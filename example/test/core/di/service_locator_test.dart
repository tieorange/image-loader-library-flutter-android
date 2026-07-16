import 'package:flutter_test/flutter_test.dart';
import 'package:image_cache_plugin_example/core/di/service_locator.dart';
import 'package:image_cache_plugin_example/features/image_gallery/domain/repositories/gallery_repository.dart';
import 'package:image_cache_plugin_example/features/image_gallery/domain/use_cases/clear_image_cache.dart';
import 'package:image_cache_plugin_example/features/image_gallery/domain/use_cases/get_images.dart';

void main() {
  tearDown(() => serviceLocator.reset());

  test('resolves the gallery domain graph', () {
    configureDependencies();

    expect(serviceLocator<GalleryRepository>(), isNotNull);
    expect(serviceLocator<GetImages>(), isNotNull);
    expect(serviceLocator<ClearImageCache>(), isNotNull);
  });
}
