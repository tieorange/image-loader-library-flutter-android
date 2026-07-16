import 'package:fpdart/fpdart.dart';

import '../failures/gallery_failure.dart';
import '../repositories/gallery_repository.dart';

final class ClearImageCache {
  const ClearImageCache(this._repository);

  final GalleryRepository _repository;

  Future<Either<GalleryFailure, Unit>> call() => _repository.clearCache();
}
