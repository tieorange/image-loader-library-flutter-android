import 'package:flutter/services.dart';

import 'cached_image_file.dart';
import 'image_cache_exception.dart';

/// Injectable boundary for native image cache operations.
abstract interface class ImageCacheClient {
  /// Loads [url], returning a path to the native cached file.
  Future<CachedImageFile> loadImage(String url);

  /// Removes the cached file for [url].
  Future<void> evictImage(String url);

  /// Removes every cached image.
  Future<void> clearCache();
}

/// MethodChannel-backed [ImageCacheClient].
final class MethodChannelImageCacheClient implements ImageCacheClient {
  /// Creates a client, optionally with a channel for testing.
  const MethodChannelImageCacheClient({
    MethodChannel channel = const MethodChannel(_channelName),
  }) : _channel = channel;

  static const _channelName = 'com.tieorange.image_cache_plugin/methods';
  final MethodChannel _channel;

  @override
  Future<CachedImageFile> loadImage(String url) async {
    final Object? value = await _invoke<Object?>('loadImage', {'url': url});
    if (value is! Map) throw _malformed();
    final Object? path = value['path'];
    final Object? source = value['source'];
    final Object? cachedAt = value['cachedAtMilliseconds'];
    if (path is! String ||
        path.isEmpty ||
        (source != 'network' && source != 'disk') ||
        cachedAt is! int) {
      throw _malformed();
    }
    return CachedImageFile(
      path: path,
      source: source == 'network'
          ? ImageCacheSource.network
          : ImageCacheSource.disk,
      cachedAtMilliseconds: cachedAt,
    );
  }

  @override
  Future<void> evictImage(String url) =>
      _invoke<void>('evictImage', {'url': url});

  @override
  Future<void> clearCache() => _invoke<void>('clearCache');

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      throw ImageCacheException(
        _codes[error.code] ?? ImageCacheErrorCode.internalError,
        error.message ?? 'The native image cache operation failed',
      );
    }
  }

  ImageCacheException _malformed() => const ImageCacheException(
    ImageCacheErrorCode.internalError,
    'The native image cache returned an invalid result',
  );

  static const _codes = <String, ImageCacheErrorCode>{
    'invalid_argument': ImageCacheErrorCode.invalidArgument,
    'network_error': ImageCacheErrorCode.networkError,
    'http_error': ImageCacheErrorCode.httpError,
    'cache_error': ImageCacheErrorCode.cacheError,
    'invalid_image': ImageCacheErrorCode.invalidImage,
    'cancelled': ImageCacheErrorCode.cancelled,
    'internal_error': ImageCacheErrorCode.internalError,
  };
}
