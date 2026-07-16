import 'package:fpdart/fpdart.dart';

import '../entities/gallery_image.dart';
import '../failures/gallery_failure.dart';

abstract interface class GalleryRepository {
  Future<Either<GalleryFailure, List<GalleryImage>>> getImages();

  Future<Either<GalleryFailure, Unit>> clearCache();
}
