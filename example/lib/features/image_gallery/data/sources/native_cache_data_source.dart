import 'package:image_cache_plugin/image_cache_plugin.dart';

import 'gallery_data_exception.dart';

abstract interface class NativeCacheDataSource {
  Future<void> clearCache();
}

final class PluginNativeCacheDataSource implements NativeCacheDataSource {
  const PluginNativeCacheDataSource(this._client);

  final ImageCacheClient _client;

  @override
  Future<void> clearCache() async {
    try {
      await _client.clearCache();
    } on ImageCacheException catch (error) {
      throw GalleryCacheException(error.message);
    }
  }
}
