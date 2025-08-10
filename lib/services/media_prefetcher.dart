import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import '../models/media_item.dart';

/// Preloads image and video assets to provide a smoother viewing experience.
class MediaPrefetcher {
  const MediaPrefetcher();

  Future<void> prefetch(BuildContext context, MediaItem item) async {
    switch (item.type) {
      case MediaType.image:
        await precacheImage(
          CachedNetworkImageProvider(item.previewUrl),
          context,
        );
        break;
      case MediaType.video:
        final controller = VideoPlayerController.networkUrl(Uri.parse(item.previewUrl));
        try {
          await controller.initialize();
        } finally {
          await controller.dispose();
        }
        break;
    }
  }
}
