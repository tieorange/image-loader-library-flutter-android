import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'cached_image_file.dart';
import 'image_cache_client.dart';

/// Loads a native cached file and renders it with a [FileImage].
class NativeCachedImage extends StatefulWidget {
  /// Creates a native cached image widget.
  const NativeCachedImage({
    required this.url,
    super.key,
    this.client = const MethodChannelImageCacheClient(),
    this.placeholder,
    this.errorBuilder,
    this.imageBuilder,
    this.fit,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.cacheWidth,
    this.cacheHeight,
  });

  final String url;
  final ImageCacheClient client;
  final Widget? placeholder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Widget Function(BuildContext context, ImageProvider provider)?
  imageBuilder;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final double? width;
  final double? height;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  final int? cacheWidth;
  final int? cacheHeight;

  @override
  State<NativeCachedImage> createState() => _NativeCachedImageState();
}

class _NativeCachedImageState extends State<NativeCachedImage> {
  CachedImageFile? _file;
  Object? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(NativeCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.client != widget.client) {
      _load();
    }
  }

  @override
  void dispose() {
    _request++;
    super.dispose();
  }

  void _load() {
    final int request = ++_request;
    _file = null;
    _error = null;
    unawaited(
      Future<CachedImageFile>.sync(
        () => widget.client.loadImage(widget.url),
      ).then(
        (CachedImageFile file) {
          if (mounted && request == _request) {
            setState(() => _file = file);
          }
        },
        onError: (Object error) {
          if (mounted && request == _request) {
            setState(() => _error = error);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Object? error = _error;
    if (error != null) {
      return widget.errorBuilder?.call(context, error) ??
          const SizedBox.shrink();
    }
    final CachedImageFile? file = _file;
    if (file == null) return widget.placeholder ?? const SizedBox.shrink();
    final ImageProvider provider = ResizeImage.resizeIfNeeded(
      widget.cacheWidth,
      widget.cacheHeight,
      FileImage(File(file.path)),
    );
    return widget.imageBuilder?.call(context, provider) ??
        Image(
          image: provider,
          errorBuilder: widget.errorBuilder == null
              ? null
              : (context, error, _) => widget.errorBuilder!(context, error),
          fit: widget.fit,
          alignment: widget.alignment,
          width: widget.width,
          height: widget.height,
          semanticLabel: widget.semanticLabel,
          excludeFromSemantics: widget.excludeFromSemantics,
        );
  }
}
