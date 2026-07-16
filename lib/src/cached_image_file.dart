/// Identifies where a cached image was obtained.
enum ImageCacheSource { network, disk }

/// A native cached image file and its cache metadata.
final class CachedImageFile {
  /// Creates cache metadata for [path].
  const CachedImageFile({
    required this.path,
    required this.source,
    required this.cachedAtMilliseconds,
  });

  /// Absolute path to the native cache file.
  final String path;

  /// Whether this request downloaded the file or found it on disk.
  final ImageCacheSource source;

  /// Successful native commit time in epoch milliseconds.
  final int cachedAtMilliseconds;
}
