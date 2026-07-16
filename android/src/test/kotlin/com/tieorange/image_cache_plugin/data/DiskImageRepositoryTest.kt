package com.tieorange.image_cache_plugin.data

import com.tieorange.image_cache_plugin.domain.CacheSource
import com.tieorange.image_cache_plugin.domain.Clock
import java.io.File
import java.nio.file.Files
import java.util.concurrent.atomic.AtomicInteger
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNotEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class DiskImageRepositoryTest {
    @Test fun `fresh entry persists across repositories and expired entry refreshes`() = runTest {
        val root = Files.createTempDirectory("image-cache").toFile()
        var now = 1_000L
        val downloads = AtomicInteger()
        val downloader = ImageDownloader { _, destination -> destination.writeText("image-${downloads.incrementAndGet()}") }
        val repository = repository(root, downloader, Clock { now })

        val first = repository.load(URL)
        val reopened = repository(root, downloader, Clock { now }).load(URL)
        assertEquals(CacheSource.DISK, reopened.source)
        assertEquals(first.file, reopened.file)

        now += FOUR_HOURS
        val refreshed = repository(root, downloader, Clock { now }).load(URL)
        assertEquals(CacheSource.NETWORK, refreshed.source)
        assertNotEquals(first.file, refreshed.file)
        assertFalse(first.file.exists())
        assertEquals(2, downloads.get())
    }

    @Test fun `same URL loads coalesce across repository instances`() = runTest {
        val root = Files.createTempDirectory("image-cache").toFile()
        val started = CompletableDeferred<Unit>()
        val release = CompletableDeferred<Unit>()
        val downloads = AtomicInteger()
        val downloader = ImageDownloader { _, destination ->
            downloads.incrementAndGet()
            started.complete(Unit)
            release.await()
            destination.writeText("image")
        }
        val firstRepository = repository(root, downloader)
        val secondRepository = repository(root, downloader)
        val first = async { firstRepository.load(URL) }
        started.await()
        val second = async { secondRepository.load(URL) }
        release.complete(Unit)
        val results = listOf(first.await(), second.await())
        assertEquals(1, downloads.get())
        assertEquals(setOf(CacheSource.NETWORK, CacheSource.DISK), results.map { it.source }.toSet())
    }

    @Test fun `eviction from another repository prevents an older commit`() = runTest {
        val root = Files.createTempDirectory("image-cache").toFile()
        val started = CompletableDeferred<Unit>()
        val release = CompletableDeferred<Unit>()
        val downloader = ImageDownloader { _, destination ->
            started.complete(Unit)
            release.await()
            destination.writeText("image")
        }
        val firstRepository = repository(root, downloader)
        val secondRepository = repository(root, downloader)
        val loading = async { firstRepository.load(URL) }
        started.await()
        secondRepository.evict(URL)
        release.complete(Unit)

        assertTrue(runCatching { loading.await() }.isFailure)
        assertEquals(0, root.walkTopDown().count { it.extension == "img" })
    }

    @Test fun `download failure leaves no committed entry`() = runTest {
        val root = Files.createTempDirectory("image-cache").toFile()
        val repository = repository(root, ImageDownloader { _, destination ->
            destination.writeText("partial")
            error("failed")
        })

        assertTrue(runCatching { repository.load(URL) }.isFailure)
        assertEquals(0, root.walkTopDown().count { it.extension == "img" || it.extension == "tmp" })
    }

    @Test fun `future commit is discarded without hiding older valid entry`() = runTest {
        val root = Files.createTempDirectory("image-cache").toFile()
        val directory = File(root, DiskImageRepository.hash(URL)).apply { mkdirs() }
        val valid = File(directory, "900-00000000-0000-4000-8000-000000000001.img").apply { writeText("valid") }
        val future = File(directory, "1100-00000000-0000-4000-8000-000000000002.img").apply { writeText("future") }
        File(directory, "999-not-a-uuid.img").writeText("malformed")
        val repository = repository(root, ImageDownloader { _, _ -> error("download not expected") })

        val result = repository.load(URL)

        assertEquals(valid, result.file)
        assertEquals(CacheSource.DISK, result.source)
        assertFalse(future.exists())
    }

    private fun TestScope.repository(
        root: File,
        downloader: ImageDownloader,
        clock: Clock = Clock { 1_000L },
    ) = DiskImageRepository(
        root = root,
        downloader = downloader,
        validator = ImageValidator {},
        clock = clock,
        ioDispatcher = StandardTestDispatcher(testScheduler),
        committer = FileCommitter { source, destination -> check(source.renameTo(destination)) },
    )

    companion object {
        private const val URL = "https://example.com/image.jpg"
        private const val FOUR_HOURS = 4L * 60 * 60 * 1000
    }
}
