import 'cached_image_file.dart';
import 'image_cache_client.dart';

/// Small facade over native image cache operations.
final class ImageCachePlugin implements ImageCacheClient {
  /// Creates a facade with an optional injectable [client].
  ImageCachePlugin({ImageCacheClient? client})
    : _client = client ?? const MethodChannelImageCacheClient();

  final ImageCacheClient _client;

  /// Loads [url] into the persistent native cache.
  @override
  Future<CachedImageFile> loadImage(String url) => _client.loadImage(url);

  /// Removes [url] from the native cache.
  @override
  Future<void> evictImage(String url) => _client.evictImage(url);

  /// Clears the native image cache.
  @override
  Future<void> clearCache() => _client.clearCache();
}
