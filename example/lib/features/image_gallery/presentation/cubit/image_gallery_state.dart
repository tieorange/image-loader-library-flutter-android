part of 'image_gallery_cubit.dart';

enum GalleryLoadStatus { initial, loading, success, failure }

enum CacheClearStatus { idle, clearing, success, failure }

final class ImageGalleryState extends Equatable {
  const ImageGalleryState({
    this.loadStatus = GalleryLoadStatus.initial,
    this.images = const [],
    this.loadFailure,
    this.clearStatus = CacheClearStatus.idle,
    this.clearFailure,
    this.cacheGeneration = 0,
  });

  final GalleryLoadStatus loadStatus;
  final List<GalleryImage> images;
  final GalleryFailure? loadFailure;
  final CacheClearStatus clearStatus;
  final GalleryFailure? clearFailure;
  final int cacheGeneration;

  ImageGalleryState copyWith({
    GalleryLoadStatus? loadStatus,
    List<GalleryImage>? images,
    GalleryFailure? loadFailure,
    bool clearLoadFailure = false,
    CacheClearStatus? clearStatus,
    GalleryFailure? clearFailure,
    bool clearClearFailure = false,
    int? cacheGeneration,
  }) {
    return ImageGalleryState(
      loadStatus: loadStatus ?? this.loadStatus,
      images: images ?? this.images,
      loadFailure: clearLoadFailure ? null : loadFailure ?? this.loadFailure,
      clearStatus: clearStatus ?? this.clearStatus,
      clearFailure: clearClearFailure
          ? null
          : clearFailure ?? this.clearFailure,
      cacheGeneration: cacheGeneration ?? this.cacheGeneration,
    );
  }

  @override
  List<Object?> get props => [
    loadStatus,
    images,
    loadFailure,
    clearStatus,
    clearFailure,
    cacheGeneration,
  ];
}
