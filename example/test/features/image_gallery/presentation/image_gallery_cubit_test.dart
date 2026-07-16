import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_cache_plugin_example/features/image_gallery/domain/entities/gallery_image.dart';
import 'package:image_cache_plugin_example/features/image_gallery/domain/failures/gallery_failure.dart';
import 'package:image_cache_plugin_example/features/image_gallery/domain/repositories/gallery_repository.dart';
import 'package:image_cache_plugin_example/features/image_gallery/domain/use_cases/clear_image_cache.dart';
import 'package:image_cache_plugin_example/features/image_gallery/domain/use_cases/get_images.dart';
import 'package:image_cache_plugin_example/features/image_gallery/presentation/cubit/image_gallery_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockGalleryRepository extends Mock implements GalleryRepository {}

void main() {
  late _MockGalleryRepository repository;
  late GetImages getImages;
  late ClearImageCache clearImageCache;

  setUp(() {
    repository = _MockGalleryRepository();
    getImages = GetImages(repository);
    clearImageCache = ClearImageCache(repository);
  });

  blocTest<ImageGalleryCubit, ImageGalleryState>(
    'loads images successfully',
    setUp: () => when(() => repository.getImages()).thenAnswer(
      (_) async => const Right([
        GalleryImage(id: 7, imageUrl: 'https://example.com/7.jpg'),
      ]),
    ),
    build: () => ImageGalleryCubit(getImages, clearImageCache),
    act: (cubit) => cubit.loadImages(),
    expect: () => const [
      ImageGalleryState(loadStatus: GalleryLoadStatus.loading),
      ImageGalleryState(
        loadStatus: GalleryLoadStatus.success,
        images: [GalleryImage(id: 7, imageUrl: 'https://example.com/7.jpg')],
      ),
    ],
  );

  blocTest<ImageGalleryCubit, ImageGalleryState>(
    'exposes a load failure',
    setUp: () => when(
      () => repository.getImages(),
    ).thenAnswer((_) async => const Left(NetworkFailure('Offline'))),
    build: () => ImageGalleryCubit(getImages, clearImageCache),
    act: (cubit) => cubit.loadImages(),
    expect: () => const [
      ImageGalleryState(loadStatus: GalleryLoadStatus.loading),
      ImageGalleryState(
        loadStatus: GalleryLoadStatus.failure,
        loadFailure: NetworkFailure('Offline'),
      ),
    ],
  );

  blocTest<ImageGalleryCubit, ImageGalleryState>(
    'retains images and advances generation after clearing',
    setUp: () => when(
      () => repository.clearCache(),
    ).thenAnswer((_) async => const Right(unit)),
    seed: () => const ImageGalleryState(
      loadStatus: GalleryLoadStatus.success,
      images: [GalleryImage(id: 1, imageUrl: 'https://example.com/1.jpg')],
    ),
    build: () => ImageGalleryCubit(getImages, clearImageCache),
    act: (cubit) => cubit.clearCache(),
    expect: () => const [
      ImageGalleryState(
        loadStatus: GalleryLoadStatus.success,
        images: [GalleryImage(id: 1, imageUrl: 'https://example.com/1.jpg')],
        clearStatus: CacheClearStatus.clearing,
      ),
      ImageGalleryState(
        loadStatus: GalleryLoadStatus.success,
        images: [GalleryImage(id: 1, imageUrl: 'https://example.com/1.jpg')],
        clearStatus: CacheClearStatus.success,
        cacheGeneration: 1,
      ),
    ],
  );

  blocTest<ImageGalleryCubit, ImageGalleryState>(
    'retains images and exposes a clear failure',
    setUp: () => when(
      () => repository.clearCache(),
    ).thenAnswer((_) async => const Left(CacheFailure('Cache is busy'))),
    seed: () => const ImageGalleryState(
      loadStatus: GalleryLoadStatus.success,
      images: [GalleryImage(id: 1, imageUrl: 'https://example.com/1.jpg')],
    ),
    build: () => ImageGalleryCubit(getImages, clearImageCache),
    act: (cubit) => cubit.clearCache(),
    expect: () => const [
      ImageGalleryState(
        loadStatus: GalleryLoadStatus.success,
        images: [GalleryImage(id: 1, imageUrl: 'https://example.com/1.jpg')],
        clearStatus: CacheClearStatus.clearing,
      ),
      ImageGalleryState(
        loadStatus: GalleryLoadStatus.success,
        images: [GalleryImage(id: 1, imageUrl: 'https://example.com/1.jpg')],
        clearStatus: CacheClearStatus.failure,
        clearFailure: CacheFailure('Cache is busy'),
      ),
    ],
  );
}
