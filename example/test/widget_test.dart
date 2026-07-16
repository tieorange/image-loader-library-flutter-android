import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_cache_plugin_example/features/image_gallery/domain/entities/gallery_image.dart';
import 'package:image_cache_plugin_example/features/image_gallery/domain/repositories/gallery_repository.dart';
import 'package:image_cache_plugin_example/features/image_gallery/domain/use_cases/clear_image_cache.dart';
import 'package:image_cache_plugin_example/features/image_gallery/domain/use_cases/get_images.dart';
import 'package:image_cache_plugin_example/features/image_gallery/presentation/cubit/image_gallery_cubit.dart';
import 'package:image_cache_plugin_example/features/image_gallery/presentation/pages/image_gallery_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockGalleryRepository extends Mock implements GalleryRepository {}

void main() {
  testWidgets('shows loaded IDs and clears the cache', (tester) async {
    final repository = _MockGalleryRepository();
    when(() => repository.getImages()).thenAnswer(
      (_) async => const Right([
        GalleryImage(id: 12, imageUrl: 'https://example.com/shared.jpg'),
        GalleryImage(id: 34, imageUrl: 'https://example.com/shared.jpg'),
      ]),
    );
    when(
      () => repository.clearCache(),
    ).thenAnswer((_) async => const Right(unit));
    final cubit = ImageGalleryCubit(
      GetImages(repository),
      ClearImageCache(repository),
    );
    await cubit.loadImages();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const ImageGalleryPage()),
      ),
    );

    expect(find.text('IMAGE 12'), findsOneWidget);
    expect(find.text('IMAGE 34'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear image cache'));
    await tester.pump();

    verify(() => repository.clearCache()).called(1);
    expect(find.textContaining('Image cache cleared'), findsOneWidget);

    await cubit.close();
  });
}
