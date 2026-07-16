sealed class GalleryDataException implements Exception {
  const GalleryDataException(this.message);

  final String message;
}

final class GalleryNetworkException extends GalleryDataException {
  const GalleryNetworkException(super.message);
}

final class GalleryServerException extends GalleryDataException {
  const GalleryServerException(super.message);
}

final class GalleryParsingException extends GalleryDataException {
  const GalleryParsingException(super.message);
}

final class GalleryCacheException extends GalleryDataException {
  const GalleryCacheException(super.message);
}
