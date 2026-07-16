package com.tieorange.image_cache_plugin.data

import com.tieorange.image_cache_plugin.domain.ImageLoaderException
import java.io.ByteArrayInputStream
import java.io.IOException
import java.io.InputStream
import java.net.HttpURLConnection
import java.nio.file.Files
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import kotlinx.coroutines.async
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.assertArrayEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.mockito.kotlin.doReturn
import org.mockito.kotlin.atLeastOnce
import org.mockito.kotlin.mock
import org.mockito.kotlin.verify

class HttpImageDownloaderTest {
    @Test fun `streams a bounded successful response and rejects excess data`() = runTest {
        val bytes = byteArrayOf(1, 2, 3, 4)
        val connection = mock<HttpURLConnection> {
            on { responseCode } doReturn 200
            on { contentLengthLong } doReturn bytes.size.toLong()
            on { inputStream } doReturn ByteArrayInputStream(bytes)
        }
        val destination = Files.createTempFile("download", ".tmp").toFile()
        HttpImageDownloader(maximumBytes = bytes.size.toLong(), openConnection = { connection })
            .download("https://example.com/image", destination)
        assertArrayEquals(bytes, destination.readBytes())

        val oversized = mock<HttpURLConnection> {
            on { responseCode } doReturn 200
            on { contentLengthLong } doReturn bytes.size.toLong()
        }
        val failure = runCatching {
            HttpImageDownloader(maximumBytes = 2, openConnection = { oversized })
                .download("https://example.com/image", destination)
        }.exceptionOrNull()
        assertTrue(failure is ImageLoaderException.Network)
    }

    @Test fun `cancellation closes a stalled response and disconnects`() = runBlocking {
        val started = CountDownLatch(1)
        val released = CountDownLatch(1)
        val closed = AtomicBoolean()
        val stalled = object : InputStream() {
            override fun read(): Int {
                started.countDown()
                released.await()
                throw IOException("closed")
            }

            override fun close() {
                closed.set(true)
                released.countDown()
            }
        }
        val connection = mock<HttpURLConnection> {
            on { responseCode } doReturn 200
            on { contentLengthLong } doReturn -1
            on { inputStream } doReturn stalled
        }
        val destination = Files.createTempFile("download", ".tmp").toFile()
        val loading = async {
            HttpImageDownloader(openConnection = { connection })
                .download("https://example.com/image", destination)
        }

        assertTrue(withContext(kotlinx.coroutines.Dispatchers.IO) { started.await(2, TimeUnit.SECONDS) })
        loading.cancelAndJoin()

        assertTrue(closed.get())
        verify(connection, atLeastOnce()).disconnect()
    }
}
