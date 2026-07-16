package com.tieorange.image_cache_plugin.domain

import java.io.File

/** Origin of a cached image returned by the repository. */
enum class CacheSource { NETWORK, DISK }

/** Immutable metadata for a complete cached image file. */
data class CachedImageFile(
    val file: File,
    val source: CacheSource,
    val cachedAtMilliseconds: Long,
)
