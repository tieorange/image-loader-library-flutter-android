package com.tieorange.image_cache_plugin.api

import com.tieorange.image_cache_plugin.domain.CachedImageFile

/** Java-friendly callback for image file loading. */
interface ImageLoaderCallback {
    fun onSuccess(result: CachedImageFile)
    fun onError(error: Exception)
}

/** Java-friendly callback for cache invalidation operations. */
interface CacheOperationCallback {
    fun onSuccess()
    fun onError(error: Exception)
}

/** Callback for ImageView target loading. */
interface ImageTargetCallback {
    fun onSuccess(result: CachedImageFile)
    fun onError(error: Exception)
}
