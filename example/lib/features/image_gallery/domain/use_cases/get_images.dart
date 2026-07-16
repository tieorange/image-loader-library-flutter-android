import 'package:fpdart/fpdart.dart';

import '../entities/gallery_image.dart';
import '../failures/gallery_failure.dart';
import '../repositories/gallery_repository.dart';

final class GetImages {
  const GetImages(this._repository);

  final GalleryRepository _repository;

  Future<Either<GalleryFailure, List<GalleryImage>>> call() =>
      _repository.getImages();
}
