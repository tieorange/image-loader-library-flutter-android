package com.tieorange.image_cache_plugin.domain

/** Persistent image loading and invalidation boundary. */
internal interface ImageRepository {
    suspend fun load(url: String): CachedImageFile
    suspend fun evict(url: String)
    suspend fun clear()
    fun generation(url: String): Generation
}

/** Process-local invalidation identity used to reject stale image assignment. */
internal data class Generation(val global: Long, val url: Long)

/** Injectable wall clock. */
internal fun interface Clock {
    fun nowMilliseconds(): Long
}
