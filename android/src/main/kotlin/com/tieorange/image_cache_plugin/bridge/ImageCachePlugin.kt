package com.tieorange.image_cache_plugin.bridge

import com.tieorange.image_cache_plugin.api.ImageLoader
import com.tieorange.image_cache_plugin.domain.CacheSource
import com.tieorange.image_cache_plugin.domain.ImageLoaderException
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/** Android registration entry point for the image cache plugin. */
class ImageCachePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var loader: ImageLoader? = null
    private var scope: CoroutineScope? = null
    private var acceptingCalls = false
    private val pending = mutableSetOf<PendingResult>()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        loader = ImageLoader(binding.applicationContext)
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
        acceptingCalls = true
        channel = MethodChannel(binding.binaryMessenger, CHANNEL).also { it.setMethodCallHandler(this) }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (!acceptingCalls) {
            result.error(CANCELLED, "The plugin is detached", null)
            return
        }
        val completion = PendingResult(result) { pending.remove(it) }.also { pending.add(it) }
        val currentLoader = loader
        val currentScope = scope
        if (currentLoader == null || currentScope == null) {
            completion.error(CANCELLED, "The plugin is detached")
            return
        }
        currentScope.launch {
            try {
                when (call.method) {
                    "loadImage" -> {
                        val url = requireUrl(call)
                        val image = currentLoader.load(url)
                        completion.success(
                            mapOf(
                                "path" to image.file.path,
                                "source" to if (image.source == CacheSource.NETWORK) "network" else "disk",
                                "cachedAtMilliseconds" to image.cachedAtMilliseconds,
                            ),
                        )
                    }
                    "evictImage" -> {
                        currentLoader.evict(requireUrl(call))
                        completion.success(null)
                    }
                    "clearCache" -> {
                        currentLoader.clear()
                        completion.success(null)
                    }
                    else -> completion.notImplemented()
                }
            } catch (error: CancellationException) {
                completion.error(CANCELLED, "The operation was cancelled")
            } catch (error: Exception) {
                val (code, message) = mapError(error)
                completion.error(code, message)
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        acceptingCalls = false
        pending.toList().forEach { it.error(CANCELLED, "The plugin was detached") }
        scope?.cancel()
        loader?.close()
        channel?.setMethodCallHandler(null)
        pending.clear()
        scope = null
        loader = null
        channel = null
    }

    private fun requireUrl(call: MethodCall): String {
        val url = (call.arguments as? Map<*, *>)?.get("url") as? String
        if (url.isNullOrBlank()) throw ImageLoaderException.InvalidArgument("A non-empty URL is required")
        return url
    }

    private fun mapError(error: Exception): Pair<String, String> = when (error) {
        is ImageLoaderException.InvalidArgument -> "invalid_argument" to error.message.orEmpty()
        is ImageLoaderException.Network -> "network_error" to "The image could not be downloaded"
        is ImageLoaderException.Http -> "http_error" to "The server returned HTTP ${error.statusCode}"
        is ImageLoaderException.Cache -> "cache_error" to "The image cache operation failed"
        is ImageLoaderException.InvalidImage -> "invalid_image" to error.message.orEmpty()
        else -> "internal_error" to "An unexpected image cache error occurred"
    }

    private companion object {
        const val CHANNEL = "com.tieorange.image_cache_plugin/methods"
        const val CANCELLED = "cancelled"
    }
}

private class PendingResult(
    private val delegate: MethodChannel.Result,
    private val onComplete: (PendingResult) -> Unit,
) {
    private val completed = AtomicBoolean(false)

    fun success(value: Any?) = complete { delegate.success(value) }
    fun error(code: String, message: String) = complete { delegate.error(code, message, null) }
    fun notImplemented() = complete { delegate.notImplemented() }

    private inline fun complete(deliver: () -> Unit) {
        if (completed.compareAndSet(false, true)) {
            onComplete(this)
            deliver()
        }
    }
}
