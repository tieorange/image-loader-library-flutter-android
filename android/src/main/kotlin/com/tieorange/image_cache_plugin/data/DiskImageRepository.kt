package com.tieorange.image_cache_plugin.data

import android.system.Os
import com.tieorange.image_cache_plugin.domain.CacheSource
import com.tieorange.image_cache_plugin.domain.CachedImageFile
import com.tieorange.image_cache_plugin.domain.Clock
import com.tieorange.image_cache_plugin.domain.Generation
import com.tieorange.image_cache_plugin.domain.ImageLoaderException
import com.tieorange.image_cache_plugin.domain.ImageRepository
import java.io.File
import java.io.IOException
import java.security.MessageDigest
import java.util.UUID
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.sync.withLock

internal class DiskImageRepository(
    private val root: File,
    private val downloader: ImageDownloader = HttpImageDownloader(),
    private val validator: ImageValidator = AndroidImageValidator(),
    private val clock: Clock = Clock(System::currentTimeMillis),
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
    private val ttlMilliseconds: Long = FOUR_HOURS,
    private val committer: FileCommitter = AndroidFileCommitter,
) : ImageRepository {
    private val coordinator = CacheCoordinatorRegistry.forRoot(root)

    override suspend fun load(url: String): CachedImageFile = withContext(ioDispatcher) {
        HttpImageDownloader.validateUrl(url)
        val key = hash(url)
        coordinator.mutex(key).withLock {
            findFresh(key)?.let { return@withLock it }
            val generation = coordinator.generation(key)
            val directory = File(root, key)
            ensureDirectory(directory)
            val temporary = File(directory, ".${UUID.randomUUID()}.tmp")
            coordinator.activeTemporaries += temporary.canonicalPath
            try {
                downloader.download(url, temporary)
                validator.validate(temporary)
                coordinator.mutationMutex.withLock {
                    if (coordinator.generation(key) != generation) throw CancellationException("Image load was invalidated")
                    val identity = UUID.randomUUID()
                    val committedAt = clock.nowMilliseconds()
                    val committed = File(directory, "$committedAt-$identity.img")
                    try { committer.rename(temporary, committed) } catch (error: Exception) { throw ImageLoaderException.Cache(error) }
                    removeCommittedExcept(directory, committed)
                    CachedImageFile(committed, CacheSource.NETWORK, committedAt)
                }
            } catch (error: CancellationException) {
                temporary.delete()
                throw error
            } catch (error: ImageLoaderException) {
                temporary.delete()
                throw error
            } catch (error: Exception) {
                temporary.delete()
                throw ImageLoaderException.Cache(error)
            } finally {
                coordinator.activeTemporaries -= temporary.canonicalPath
            }
        }
    }

    override suspend fun evict(url: String) = withContext(ioDispatcher) {
        HttpImageDownloader.validateUrl(url)
        val key = hash(url)
        coordinator.mutationMutex.withLock {
            coordinator.increment(key)
            deleteInactive(File(root, key))
        }
    }

    override suspend fun clear() = withContext(ioDispatcher) {
        coordinator.mutationMutex.withLock {
            coordinator.incrementAll()
            root.listFiles()?.forEach(::deleteInactive)
            Unit
        }
    }

    override fun generation(url: String): Generation = coordinator.generation(hash(url))

    private suspend fun findFresh(key: String): CachedImageFile? = coordinator.mutationMutex.withLock {
        val directory = File(root, key)
        val now = clock.nowMilliseconds()
        val entries = directory.listFiles().orEmpty()
            .mapNotNull { file -> parseCommit(file)?.let { timestamp -> file to timestamp } }
            .sortedWith(compareByDescending<Pair<File, Long>> { it.second }.thenByDescending { it.first.name })
        val futureEntries = entries.filter { it.second > now }
        futureEntries.forEach { it.first.delete() }
        val eligibleEntries = entries.filter { it.second <= now }
        val newest = eligibleEntries.firstOrNull { candidate ->
            try {
                validator.validate(candidate.first)
                true
            } catch (_: ImageLoaderException.InvalidImage) {
                candidate.first.delete()
                false
            }
        }
        eligibleEntries.filter { it != newest }.forEach { it.first.delete() }
        cleanTemporaries(directory, now)
        if (newest == null || now - newest.second >= ttlMilliseconds || !newest.first.isFile) {
            newest?.first?.delete()
            null
        } else {
            CachedImageFile(newest.first, CacheSource.DISK, newest.second)
        }
    }

    private fun cleanTemporaries(directory: File, now: Long) {
        directory.listFiles { file -> file.name.startsWith(".") && file.name.endsWith(".tmp") }
            ?.filter { it.canonicalPath !in coordinator.activeTemporaries && now - it.lastModified() >= TEMP_MAX_AGE }
            ?.forEach(File::delete)
    }

    private fun parseCommit(file: File): Long? {
        if (!file.isFile) return null
        val match = COMMITTED_FILE.matchEntire(file.name) ?: return null
        return match.groupValues[1].toLongOrNull()
    }

    private fun removeCommittedExcept(directory: File, current: File) {
        directory.listFiles()?.filter { it != current && parseCommit(it) != null }?.forEach(File::delete)
    }

    private fun ensureDirectory(directory: File) {
        if ((!root.exists() && !root.mkdirs()) || (!directory.exists() && !directory.mkdirs())) {
            throw ImageLoaderException.Cache(IOException("Cache directory could not be created"))
        }
    }

    private fun deleteInactive(file: File) {
        if (file.canonicalPath in coordinator.activeTemporaries) return
        if (file.isDirectory) {
            file.listFiles()?.forEach(::deleteInactive)
            return
        }
        if (file.exists() && !file.delete()) {
            throw ImageLoaderException.Cache(IOException("Cache entry could not be removed"))
        }
    }

    companion object {
        private const val FOUR_HOURS = 4L * 60 * 60 * 1000
        private const val TEMP_MAX_AGE = 60L * 60 * 1000
        private val COMMITTED_FILE = Regex(
            "^(0|[1-9][0-9]*)-[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\\.img$",
        )
        fun hash(url: String): String = MessageDigest.getInstance("SHA-256")
            .digest(url.toByteArray(Charsets.UTF_8)).joinToString("") { "%02x".format(it) }
    }
}

internal fun interface FileCommitter { fun rename(source: File, destination: File) }

internal object AndroidFileCommitter : FileCommitter {
    override fun rename(source: File, destination: File) = Os.rename(source.path, destination.path)
}
