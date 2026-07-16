/// Stable categories reported by the native image cache.
enum ImageCacheErrorCode {
  invalidArgument,
  networkError,
  httpError,
  cacheError,
  invalidImage,
  cancelled,
  internalError,
}

/// A typed failure from an image cache operation.
final class ImageCacheException implements Exception {
  /// Creates an image cache failure.
  const ImageCacheException(this.code, this.message);

  /// Stable failure category.
  final ImageCacheErrorCode code;

  /// Safe, user-presentable failure description.
  final String message;

  @override
  String toString() => 'ImageCacheException($code, $message)';
}
