package com.tieorange.image_cache_plugin.bridge

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** Android registration entry point for the image cache plugin. */
class ImageCachePlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) = Unit

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) = Unit
}
