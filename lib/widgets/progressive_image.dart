import 'package:flutter/material.dart';

/// Displays a low resolution thumbnail that fades into the main image once
/// loaded. Shows a fallback icon if the main image fails to load.
class ProgressiveImage extends StatefulWidget {
  const ProgressiveImage({
    super.key,
    required this.imageUrl,
    required this.thumbUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.image,
    this.thumb,
  });

  final String imageUrl;
  final String thumbUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double? borderRadius;

  /// Optional [ImageProvider] overrides primarily for testing or caching.
  final ImageProvider? image;
  final ImageProvider? thumb;

  @override
  State<ProgressiveImage> createState() => _ProgressiveImageState();
}

class _ProgressiveImageState extends State<ProgressiveImage> {
  bool _loaded = false;
  bool _errored = false;

  ImageProvider get _mainProvider =>
      widget.image ?? NetworkImage(widget.imageUrl);
  ImageProvider get _thumbProvider =>
      widget.thumb ?? NetworkImage(widget.thumbUrl);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(_thumbProvider, context);
    precacheImage(_mainProvider, context);
  }

  @override
  Widget build(BuildContext context) {
    final border = widget.borderRadius != null
        ? BorderRadius.circular(widget.borderRadius!)
        : null;

    if (_errored) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Icon(Icons.broken_image),
      );
    }

    final thumb = Image(
      image: _thumbProvider,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );

    final main = Image(
      image: _mainProvider,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _errored = true);
          }
        });
        return const SizedBox();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _loaded = true);
            }
          });
        }
        return child;
      },
    );

    return ClipRRect(
      borderRadius: border ?? BorderRadius.zero,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(child: thumb),
          AnimatedOpacity(
            opacity: _loaded ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: main,
          ),
        ],
      ),
    );
  }
}

