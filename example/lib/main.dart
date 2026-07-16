import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/service_locator.dart';
import 'features/image_gallery/presentation/cubit/image_gallery_cubit.dart';
import 'features/image_gallery/presentation/pages/image_gallery_page.dart';

void main() {
  configureDependencies();
  runApp(const ImageCacheExampleApp());
}

class ImageCacheExampleApp extends StatelessWidget {
  const ImageCacheExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006C67),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F1EA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF4F1EA),
          surfaceTintColor: Colors.transparent,
        ),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) {
          final cubit = serviceLocator<ImageGalleryCubit>();
          unawaited(cubit.loadImages());
          return cubit;
        },
        child: const ImageGalleryPage(),
      ),
    );
  }
}
