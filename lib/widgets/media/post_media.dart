import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'video_player_view.dart';

import '../../models/media_item.dart';
import '../../screens/media_viewer.dart';

/// Renders attachments within the feed.
class PostMedia extends StatelessWidget {
  const PostMedia({super.key, required this.media});

  final List<MediaItem> media;

  double _clampAspectRatio(double ratio) {
    const double minRatio = 4 / 5;
    const double maxRatio = 16 / 9;
    if (ratio < minRatio) return minRatio;
    if (ratio > maxRatio) return maxRatio;
    return ratio;
  }

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();
    final MediaItem first = media.first;
    final double aspect = _clampAspectRatio(first.aspectRatio);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    Widget child;
    switch (first.type) {
      case MediaType.image:
        child = CachedNetworkImage(
          imageUrl: first.previewUrl,
          placeholder: (context, url) => first.blurHash != null
              ? BlurHash(
                  hash: first.blurHash!,
                  imageFit: BoxFit.cover,
                )
              : Container(color: colorScheme.surfaceVariant),
          fit: BoxFit.cover,
        );
        break;
      case MediaType.video:
        child = VideoPlayerView(url: Uri.parse(first.previewUrl));
        break;
    }
    return Semantics(
      label: first.type == MediaType.image ? 'Image preview' : 'Video preview',
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MediaViewer(media: media, initialIndex: 0),
          ),
        ),
        child: AspectRatio(
          aspectRatio: aspect,
          child: Hero(
            tag: first.fullUrl,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  child,
                  if (media.length > 1)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          media.length.toString(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            colorScheme.scrim.withOpacity(0.7),
                            colorScheme.scrim.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
