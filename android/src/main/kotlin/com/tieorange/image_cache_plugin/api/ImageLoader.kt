package com.tieorange.image_cache_plugin.api

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.drawable.Drawable
import android.os.Looper
import android.util.LruCache
import android.widget.ImageView
import com.tieorange.image_cache_plugin.data.DiskImageRepository
import com.tieorange.image_cache_plugin.domain.CachedImageFile
import com.tieorange.image_cache_plugin.domain.Generation
import com.tieorange.image_cache_plugin.domain.ImageRepository
import java.io.Closeable
import java.util.WeakHashMap
import java.util.concurrent.atomic.AtomicBoolean
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** Native image loader with persistent disk caching and bounded decoded memory caching. */
class ImageLoader private constructor(
    private val repository: ImageRepository,
    private val scope: CoroutineScope,
) : Closeable {
    /** Creates a loader storing files below `noBackupFilesDir/image_cache_plugin`. */
    constructor(context: Context) : this(
        DiskImageRepository(context.applicationContext.noBackupFilesDir.resolve("image_cache_plugin")),
        CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate),
    )

    private val closed = AtomicBoolean(false)
    private val targets = WeakHashMap<ImageView, TargetRequest>()
    private val memory = object : LruCache<String, MemoryEntry>((Runtime.getRuntime().maxMemory() / 8).coerceAtMost(Int.MAX_VALUE.toLong()).toInt()) {
        override fun sizeOf(key: String, value: MemoryEntry): Int = value.bitmap.byteCount
    }

    /** Loads an image file, downloading it when no fresh disk entry exists. */
    @JvmSynthetic suspend fun load(url: String): CachedImageFile {
        checkOpen()
        return repository.load(url)
    }

    /** Evicts one URL from disk and decoded memory. */
    @JvmSynthetic suspend fun evict(url: String) {
        checkOpen()
        repository.evict(url)
        withContext(NonCancellable + Dispatchers.Main.immediate) {
            memory.remove(url)
            val matching = targets.filterValues { it.url == url }
            matching.values.forEach { it.request.cancel() }
            matching.forEach { (target, request) ->
                if (targets[target] === request) targets.remove(target)
            }
        }
    }

    /** Clears disk and decoded memory caches. */
    @JvmSynthetic suspend fun clear() {
        checkOpen()
        repository.clear()
        withContext(NonCancellable + Dispatchers.Main.immediate) {
            memory.evictAll()
            targets.values.forEach { it.request.cancel() }
            targets.clear()
        }
    }

    /** Loads an image and reports completion on the main thread. */
    fun load(url: String, callback: ImageLoaderCallback): ImageRequest = request {
        val result = try {
            repository.load(url)
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            currentCoroutineContext().ensureActive()
            callback.onError(error)
            return@request
        }
        currentCoroutineContext().ensureActive()
        callback.onSuccess(result)
    }

    /** Evicts one URL and reports completion on the main thread. */
    fun evict(url: String, callback: CacheOperationCallback): ImageRequest = request {
        try {
            evict(url)
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            currentCoroutineContext().ensureActive()
            callback.onError(error)
            return@request
        }
        currentCoroutineContext().ensureActive()
        callback.onSuccess()
    }

    /** Clears all entries and reports completion on the main thread. */
    fun clear(callback: CacheOperationCallback): ImageRequest = request {
        try {
            clear()
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            currentCoroutineContext().ensureActive()
            callback.onError(error)
            return@request
        }
        currentCoroutineContext().ensureActive()
        callback.onSuccess()
    }

    /** Loads into an ImageView. This synchronous registration method requires the main thread. */
    @JvmOverloads fun loadInto(
        url: String,
        target: ImageView,
        placeholder: Drawable? = null,
        callback: ImageTargetCallback? = null,
    ): ImageRequest {
        checkMainThread()
        checkOpen()
        targets.remove(target)?.request?.cancel()
        target.setImageDrawable(placeholder)
        lateinit var handle: ImageRequest
        val job = scope.launch(start = CoroutineStart.LAZY) {
            var completion: Pair<CachedImageFile, Bitmap>? = null
            try {
                val captured = repository.generation(url)
                val result = repository.load(url)
                val displayMetrics = target.resources.displayMetrics
                val decodeWidth = target.width.takeIf { it > 0 } ?: displayMetrics.widthPixels.coerceIn(1, MAX_FALLBACK_DIMENSION)
                val decodeHeight = target.height.takeIf { it > 0 } ?: displayMetrics.heightPixels.coerceIn(1, MAX_FALLBACK_DIMENSION)
                val bitmap = memory.get(url)?.takeIf {
                    it.generation == captured && it.path == result.file.path
                }?.bitmap ?: withContext(Dispatchers.IO) {
                    decodeSampled(result.file.path, decodeWidth, decodeHeight)
                }.also { memory.put(url, MemoryEntry(it, captured, result.file.path)) }
                ensureActive()
                if (targets[target]?.request === handle && repository.generation(url) == captured) {
                    completion = result to bitmap
                }
            } catch (_: CancellationException) {
            } catch (error: Exception) {
                currentCoroutineContext().ensureActive()
                if (targets[target]?.request === handle) {
                    callback?.onError(error)
                }
            } finally {
                if (targets[target]?.request === handle) targets.remove(target)
            }
            completion?.let { (result, bitmap) ->
                target.setImageBitmap(bitmap)
                callback?.onSuccess(result)
            }
        }
        handle = ImageRequest(job)
        targets[target] = TargetRequest(url, handle)
        job.start()
        return handle
    }

    /** Loads into an ImageView using a resource placeholder. Requires the main thread. */
    @JvmOverloads fun loadInto(
        url: String,
        target: ImageView,
        placeholderResource: Int,
        callback: ImageTargetCallback? = null,
    ): ImageRequest {
        checkMainThread()
        return loadInto(url, target, target.context.getDrawable(placeholderResource), callback)
    }

    /** Cancels owned work and releases decoded memory. Must be called on the main thread. */
    override fun close() {
        checkMainThread()
        if (closed.compareAndSet(false, true)) {
            scope.cancel()
            targets.clear()
            memory.evictAll()
        }
    }

    private fun request(block: suspend () -> Unit): ImageRequest {
        checkOpen()
        return ImageRequest(scope.launch { block() })
    }

    private fun checkOpen() = check(!closed.get()) { "ImageLoader is closed" }

    private fun checkMainThread() = check(Looper.myLooper() == Looper.getMainLooper()) {
        "ImageLoader target and lifecycle methods must be called on the main thread"
    }

    private fun decodeSampled(path: String, targetWidth: Int, targetHeight: Int): Bitmap {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        var sample = 1
        val width = targetWidth.coerceAtLeast(1)
        val height = targetHeight.coerceAtLeast(1)
        while (bounds.outWidth / (sample * 2) >= width && bounds.outHeight / (sample * 2) >= height) sample *= 2
        return BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
            ?: error("Cached image could not be decoded")
    }

    private companion object {
        const val MAX_FALLBACK_DIMENSION = 2_048
    }
}

private data class MemoryEntry(val bitmap: Bitmap, val generation: Generation, val path: String)
