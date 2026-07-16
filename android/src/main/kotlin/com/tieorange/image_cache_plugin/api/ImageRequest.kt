package com.tieorange.image_cache_plugin.api

import java.util.concurrent.atomic.AtomicBoolean
import kotlinx.coroutines.Job

/** Cancellable handle for an image target request. */
class ImageRequest internal constructor(internal val job: Job) {
    private val cancelled = AtomicBoolean(false)

    /** Cancels this request and prevents subsequent target or callback updates. */
    fun cancel() {
        cancelled.set(true)
        job.cancel()
    }

    /** True after this request has been explicitly cancelled. */
    val isCancelled: Boolean get() = cancelled.get()
}

internal data class TargetRequest(val url: String, val request: ImageRequest)
