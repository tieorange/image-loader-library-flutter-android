import 'package:fpdart/fpdart.dart';

import '../../domain/entities/gallery_image.dart';
import '../../domain/failures/gallery_failure.dart';
import '../../domain/repositories/gallery_repository.dart';
import '../sources/gallery_data_exception.dart';
import '../sources/gallery_remote_data_source.dart';
import '../sources/native_cache_data_source.dart';

final class GalleryRepositoryImpl implements GalleryRepository {
  const GalleryRepositoryImpl(this._remoteDataSource, this._cacheDataSource);

  final GalleryRemoteDataSource _remoteDataSource;
  final NativeCacheDataSource _cacheDataSource;

  @override
  Future<Either<GalleryFailure, List<GalleryImage>>> getImages() async {
    try {
      final images = await _remoteDataSource.getImages();
      return Right(images.map((dto) => dto.toEntity()).toList(growable: false));
    } on GalleryNetworkException catch (error) {
      return Left(NetworkFailure(error.message));
    } on GalleryServerException catch (error) {
      return Left(ServerFailure(error.message));
    } on GalleryParsingException catch (error) {
      return Left(ParsingFailure(error.message));
    } on Exception {
      return const Left(UnknownFailure('Unable to load the image gallery'));
    }
  }

  @override
  Future<Either<GalleryFailure, Unit>> clearCache() async {
    try {
      await _cacheDataSource.clearCache();
      return const Right(unit);
    } on GalleryCacheException catch (error) {
      return Left(CacheFailure(error.message));
    } on Exception {
      return const Left(UnknownFailure('Unable to clear the image cache'));
    }
  }
}
