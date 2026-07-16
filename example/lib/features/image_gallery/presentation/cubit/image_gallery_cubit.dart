import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/gallery_image.dart';
import '../../domain/failures/gallery_failure.dart';
import '../../domain/use_cases/clear_image_cache.dart';
import '../../domain/use_cases/get_images.dart';

part 'image_gallery_state.dart';

final class ImageGalleryCubit extends Cubit<ImageGalleryState> {
  ImageGalleryCubit(this._getImages, this._clearImageCache)
    : super(const ImageGalleryState());

  final GetImages _getImages;
  final ClearImageCache _clearImageCache;

  Future<void> loadImages() async {
    if (state.loadStatus == GalleryLoadStatus.loading) return;
    emit(
      state.copyWith(
        loadStatus: GalleryLoadStatus.loading,
        clearLoadFailure: true,
      ),
    );
    final result = await _getImages();
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          loadStatus: GalleryLoadStatus.failure,
          loadFailure: failure,
        ),
      ),
      (images) => emit(
        state.copyWith(
          loadStatus: GalleryLoadStatus.success,
          images: List.unmodifiable(images),
          clearLoadFailure: true,
        ),
      ),
    );
  }

  Future<void> retry() => loadImages();

  Future<void> clearCache() async {
    if (state.clearStatus == CacheClearStatus.clearing) return;
    emit(
      state.copyWith(
        clearStatus: CacheClearStatus.clearing,
        clearClearFailure: true,
      ),
    );
    final result = await _clearImageCache();
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          clearStatus: CacheClearStatus.failure,
          clearFailure: failure,
        ),
      ),
      (_) => emit(
        state.copyWith(
          clearStatus: CacheClearStatus.success,
          clearClearFailure: true,
          cacheGeneration: state.cacheGeneration + 1,
        ),
      ),
    );
  }
}
