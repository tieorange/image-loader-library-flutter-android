import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cache_plugin/image_cache_plugin.dart';

import '../../domain/entities/gallery_image.dart';
import '../cubit/image_gallery_cubit.dart';

class ImageGalleryPage extends StatelessWidget {
  const ImageGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ImageGalleryCubit, ImageGalleryState>(
      listenWhen: (previous, current) =>
          previous.clearStatus != current.clearStatus &&
          (current.clearStatus == CacheClearStatus.success ||
              current.clearStatus == CacheClearStatus.failure),
      listener: (context, state) {
        final failed = state.clearStatus == CacheClearStatus.failure;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failed
                  ? state.clearFailure?.message ?? 'Could not clear the cache.'
                  : 'Image cache cleared. Reloading visible images.',
            ),
          ),
        );
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Native image shelf'),
                Text(
                  'Four-hour disk cache',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                ),
              ],
            ),
            actions: [
              if (state.clearStatus == CacheClearStatus.clearing)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              else
                IconButton(
                  tooltip: 'Clear image cache',
                  onPressed: () =>
                      context.read<ImageGalleryCubit>().clearCache(),
                  icon: const Icon(Icons.cleaning_services_outlined),
                ),
            ],
          ),
          body: SafeArea(child: _GalleryBody(state: state)),
        );
      },
    );
  }
}

class _GalleryBody extends StatelessWidget {
  const _GalleryBody({required this.state});

  final ImageGalleryState state;

  @override
  Widget build(BuildContext context) {
    if (state.loadStatus == GalleryLoadStatus.loading && state.images.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.loadStatus == GalleryLoadStatus.failure && state.images.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: 16),
              Text(
                state.loadFailure?.message ??
                    'The gallery could not be loaded.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.read<ImageGalleryCubit>().retry(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry gallery'),
              ),
            ],
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 600
            ? 3
            : 2;
        const horizontalPadding = 32.0;
        const spacing = 12.0;
        const labelHeight = 52.0;
        final tileWidth =
            (constraints.maxWidth -
                horizontalPadding -
                spacing * (columns - 1)) /
            columns;
        final tileHeight = tileWidth * 9 / 16 + labelHeight;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: tileWidth / tileHeight,
          ),
          itemCount: state.images.length,
          itemBuilder: (context, index) => _GalleryTile(
            key: ValueKey(
              '${state.cacheGeneration}:$index:${state.images[index].id}:'
              '${state.images[index].imageUrl}',
            ),
            image: state.images[index],
          ),
        );
      },
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.image, super.key});

  final GalleryImage image;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Gallery image ${image.id}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: NativeCachedImage(
                url: image.imageUrl,
                fit: BoxFit.contain,
                cacheWidth: 720,
                cacheHeight: 720,
                excludeFromSemantics: true,
                placeholder: const ColoredBox(
                  color: Color(0xFFE1E7E4),
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorBuilder: (context, error) => const ColoredBox(
                  color: Color(0xFFF0DDD7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_outlined),
                        SizedBox(height: 6),
                        Text('Image unavailable'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'IMAGE ${image.id}',
                    semanticsLabel: 'Image ID ${image.id}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
