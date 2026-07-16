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
            title: const Text(
              'Image gallery',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: state.clearStatus == CacheClearStatus.clearing
                    ? const Padding(
                        key: ValueKey('clearing'),
                        padding: EdgeInsets.all(16),
                        child: SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    : IconButton(
                        key: const ValueKey('clear'),
                        tooltip: 'Clear image cache',
                        onPressed: () =>
                            context.read<ImageGalleryCubit>().clearCache(),
                        icon: const Icon(Icons.cleaning_services_outlined),
                      ),
              ),
            ],
          ),
          body: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.025),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _GalleryBody(
                key: ValueKey(state.loadStatus),
                state: state,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GalleryBody extends StatelessWidget {
  const _GalleryBody({required this.state, super.key});

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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: state.images.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: _GalleryTile(
            key: ValueKey(
              '${state.cacheGeneration}:$index:${state.images[index].id}:'
              '${state.images[index].imageUrl}',
            ),
            image: state.images[index],
          ),
        ),
      ),
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
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              NativeCachedImage(
                url: image.imageUrl,
                cacheWidth: 1080,
                excludeFromSemantics: true,
                imageBuilder: (context, provider) => TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0.0, end: 1.0),
                  child: Image(image: provider, fit: BoxFit.cover),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: 0.98 + value * 0.02,
                        child: child,
                      ),
                    );
                  },
                ),
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
              Positioned(
                left: 12,
                bottom: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xE6192523),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    child: Text(
                      'IMAGE ${image.id}',
                      semanticsLabel: 'Image ID ${image.id}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
