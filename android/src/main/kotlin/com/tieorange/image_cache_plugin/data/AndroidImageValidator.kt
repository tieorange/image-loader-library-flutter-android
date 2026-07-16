package com.tieorange.image_cache_plugin.data

import android.graphics.BitmapFactory
import com.tieorange.image_cache_plugin.domain.ImageLoaderException
import java.io.File

internal fun interface ImageValidator { fun validate(file: File) }

internal class AndroidImageValidator(
    private val maximumWidth: Int = 16_384,
    private val maximumHeight: Int = 16_384,
    private val maximumPixels: Long = 100_000_000,
) : ImageValidator {
    override fun validate(file: File) {
        val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(file.path, options)
        val width = options.outWidth
        val height = options.outHeight
        if (width <= 0 || height <= 0 || width > maximumWidth || height > maximumHeight || width.toLong() * height > maximumPixels) {
            throw ImageLoaderException.InvalidImage("Downloaded content is not a supported image")
        }
    }
}
