import 'package:flutter_test/flutter_test.dart';
import 'package:image_cache_plugin_example/features/image_gallery/data/models/gallery_image_dto.dart';
import 'package:image_cache_plugin_example/features/image_gallery/data/repositories/gallery_repository_impl.dart';
import 'package:image_cache_plugin_example/features/image_gallery/data/sources/gallery_data_exception.dart';
import 'package:image_cache_plugin_example/features/image_gallery/data/sources/gallery_remote_data_source.dart';
import 'package:image_cache_plugin_example/features/image_gallery/data/sources/native_cache_data_source.dart';
import 'package:image_cache_plugin_example/features/image_gallery/domain/entities/gallery_image.dart';
import 'package:image_cache_plugin_example/features/image_gallery/domain/failures/gallery_failure.dart';
import 'package:mocktail/mocktail.dart';

final class MockGalleryRemoteDataSource extends Mock
    implements GalleryRemoteDataSource {}

final class MockNativeCacheDataSource extends Mock
    implements NativeCacheDataSource {}

void main() {
  late MockGalleryRemoteDataSource remote;
  late MockNativeCacheDataSource cache;
  late GalleryRepositoryImpl repository;

  setUp(() {
    remote = MockGalleryRemoteDataSource();
    cache = MockNativeCacheDataSource();
    repository = GalleryRepositoryImpl(remote, cache);
  });

  test('returns entities without reordering or deduplicating', () async {
    when(() => remote.getImages()).thenAnswer(
      (_) async => const [
        GalleryImageDto(id: 2, imageUrl: 'https://example.com/2.jpg'),
        GalleryImageDto(id: 2, imageUrl: 'https://example.com/2.jpg'),
        GalleryImageDto(id: 1, imageUrl: 'https://example.com/1.jpg'),
      ],
    );

    final result = await repository.getImages();

    expect(result.getOrElse((_) => const []), const [
      GalleryImage(id: 2, imageUrl: 'https://example.com/2.jpg'),
      GalleryImage(id: 2, imageUrl: 'https://example.com/2.jpg'),
      GalleryImage(id: 1, imageUrl: 'https://example.com/1.jpg'),
    ]);
  });

  test('maps a remote parsing exception to ParsingFailure', () async {
    when(
      () => remote.getImages(),
    ).thenThrow(const GalleryParsingException('Malformed manifest'));

    final result = await repository.getImages();

    expect(
      result.getLeft().toNullable(),
      const ParsingFailure('Malformed manifest'),
    );
  });

  test('maps a cache exception to CacheFailure', () async {
    when(
      () => cache.clearCache(),
    ).thenThrow(const GalleryCacheException('Native clear failed'));

    final result = await repository.clearCache();

    expect(
      result.getLeft().toNullable(),
      const CacheFailure('Native clear failed'),
    );
  });
}
