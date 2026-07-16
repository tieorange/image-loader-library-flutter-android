package com.tieorange.image_cache_plugin.domain

/** Typed failures produced by the native image loading core. */
sealed class ImageLoaderException(message: String, cause: Throwable? = null) : Exception(message, cause) {
    class InvalidArgument(message: String) : ImageLoaderException(message)
    class Network(cause: Throwable) : ImageLoaderException("The image could not be downloaded", cause)
    class Http(val statusCode: Int) : ImageLoaderException("The server returned HTTP $statusCode")
    class Cache(cause: Throwable) : ImageLoaderException("The image cache operation failed", cause)
    class InvalidImage(message: String) : ImageLoaderException(message)
}
