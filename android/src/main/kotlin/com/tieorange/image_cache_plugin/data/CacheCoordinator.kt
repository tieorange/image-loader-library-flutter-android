package com.tieorange.image_cache_plugin.data

import com.tieorange.image_cache_plugin.domain.Generation
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import kotlinx.coroutines.sync.Mutex

internal class CacheCoordinator {
    val mutationMutex = Mutex()
    private val urlMutexes = ConcurrentHashMap<String, Mutex>()
    private val urlGenerations = ConcurrentHashMap<String, Long>()
    val activeTemporaries = ConcurrentHashMap.newKeySet<String>()
    @Volatile private var globalGeneration = 0L

    fun mutex(key: String): Mutex = urlMutexes.computeIfAbsent(key) { Mutex() }
    fun generation(key: String) = Generation(globalGeneration, urlGenerations[key] ?: 0L)
    fun increment(key: String) { urlGenerations.merge(key, 1L, Long::plus) }
    fun incrementAll() { globalGeneration += 1L }
}

internal object CacheCoordinatorRegistry {
    private val coordinators = ConcurrentHashMap<String, CacheCoordinator>()
    fun forRoot(root: File): CacheCoordinator =
        coordinators.computeIfAbsent(root.canonicalPath) { CacheCoordinator() }
}
