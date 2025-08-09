// lib/models/media_item.dart

class MediaItem {
  final String id;
  final String url;
  final String type; // e.g. image, video, audio
  final String? thumbnailUrl;
  final String? previewUrl;
  final String? blurHash;

  MediaItem({
    required this.id,
    required this.url,
    required this.type,
    this.thumbnailUrl,
    this.previewUrl,
    this.blurHash,
  });
}
