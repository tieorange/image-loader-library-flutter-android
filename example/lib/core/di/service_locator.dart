import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:image_cache_plugin/image_cache_plugin.dart';

import '../../features/image_gallery/data/repositories/gallery_repository_impl.dart';
import '../../features/image_gallery/data/sources/gallery_remote_data_source.dart';
import '../../features/image_gallery/data/sources/native_cache_data_source.dart';
import '../../features/image_gallery/domain/repositories/gallery_repository.dart';
import '../../features/image_gallery/domain/use_cases/clear_image_cache.dart';
import '../../features/image_gallery/domain/use_cases/get_images.dart';

final GetIt serviceLocator = GetIt.instance;

void configureDependencies() {
  serviceLocator
    ..registerLazySingleton<HttpClient>(
      HttpClient.new,
      dispose: (client) {
        client.close(force: true);
      },
    )
    ..registerLazySingleton<ImageCacheClient>(MethodChannelImageCacheClient.new)
    ..registerLazySingleton<GalleryRemoteDataSource>(
      () => HttpGalleryRemoteDataSource(serviceLocator<HttpClient>()),
    )
    ..registerLazySingleton<NativeCacheDataSource>(
      () => PluginNativeCacheDataSource(serviceLocator<ImageCacheClient>()),
    )
    ..registerLazySingleton<GalleryRepository>(
      () => GalleryRepositoryImpl(
        serviceLocator<GalleryRemoteDataSource>(),
        serviceLocator<NativeCacheDataSource>(),
      ),
    )
    ..registerLazySingleton(
      () => GetImages(serviceLocator<GalleryRepository>()),
    )
    ..registerLazySingleton(
      () => ClearImageCache(serviceLocator<GalleryRepository>()),
    );
}
