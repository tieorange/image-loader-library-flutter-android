package com.tieorange.image_cache_plugin.data

import com.tieorange.image_cache_plugin.domain.ImageLoaderException
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URI
import java.net.URL
import java.util.concurrent.atomic.AtomicReference
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.runInterruptible

internal fun interface ImageDownloader { suspend fun download(url: String, destination: File) }

internal class HttpImageDownloader(
    private val connectTimeoutMilliseconds: Int = 15_000,
    private val readTimeoutMilliseconds: Int = 30_000,
    private val maximumBytes: Long = 100L * 1024 * 1024,
    private val openConnection: (URL) -> HttpURLConnection = { it.openConnection() as HttpURLConnection },
) : ImageDownloader {
    override suspend fun download(url: String, destination: File) {
        var current = validateUrl(url)
        val visited = mutableSetOf<String>()
        repeat(6) { redirectCount ->
            if (!visited.add(current.toString())) throw ImageLoaderException.Network(IOException("Redirect loop"))
            val connection = openConnection(current.toURL()).apply {
                connectTimeout = connectTimeoutMilliseconds
                readTimeout = readTimeoutMilliseconds
                instanceFollowRedirects = false
                useCaches = false
            }
            try {
                val redirected = runWithCancellationClose(connection) { inputReference ->
                    val status = connection.responseCode
                    if (status in 300..399) {
                        if (redirectCount == 5) throw ImageLoaderException.Network(IOException("Too many redirects"))
                        val location = connection.getHeaderField("Location")
                            ?: throw ImageLoaderException.Network(IOException("Redirect has no location"))
                        val next = validateUrl(current.resolve(location).toString())
                        if (current.scheme == "https" && next.scheme == "http") {
                            throw ImageLoaderException.Network(IOException("HTTPS downgrade redirect rejected"))
                        }
                        return@runWithCancellationClose next
                    }
                    if (status !in 200..299) throw ImageLoaderException.Http(status)
                    val declaredLength = connection.contentLengthLong
                    if (declaredLength > maximumBytes) throw ImageLoaderException.Network(IOException("Image exceeds encoded size limit"))
                    connection.inputStream.use { input ->
                        inputReference.set(input)
                        FileOutputStream(destination).use { output ->
                            val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                            var total = 0L
                            while (true) {
                                val count = input.read(buffer)
                                if (count < 0) break
                                total += count
                                if (total > maximumBytes) throw ImageLoaderException.Network(IOException("Image exceeds encoded size limit"))
                                output.write(buffer, 0, count)
                            }
                            output.fd.sync()
                        }
                    }
                    null
                }
                if (redirected == null) return
                current = redirected
            } catch (error: ImageLoaderException) {
                throw error
            } catch (error: IOException) {
                currentCoroutineContext().ensureActive()
                throw ImageLoaderException.Network(error)
            } finally {
                connection.disconnect()
            }
        }
    }

    private suspend fun runWithCancellationClose(
        connection: HttpURLConnection,
        block: (AtomicReference<java.io.InputStream?>) -> URI?,
    ): URI? = coroutineScope {
        val input = AtomicReference<java.io.InputStream?>()
        val closer = launch(start = CoroutineStart.UNDISPATCHED) {
            try {
                awaitCancellation()
            } finally {
                try {
                    input.get()?.close()
                } catch (_: IOException) {
                }
                connection.disconnect()
            }
        }
        try {
            runInterruptible(Dispatchers.IO) { block(input) }
        } finally {
            closer.cancelAndJoin()
        }
    }

    companion object {
        fun validateUrl(value: String): URI {
            val uri = try { URI(value) } catch (_: Exception) { throw ImageLoaderException.InvalidArgument("URL is invalid") }
            if ((uri.scheme != "http" && uri.scheme != "https") || uri.host.isNullOrBlank() || uri.userInfo != null) {
                throw ImageLoaderException.InvalidArgument("URL must be an HTTP(S) URL without credentials")
            }
            return uri
        }
    }
}
