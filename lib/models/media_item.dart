/// Represents an image or video used in a story.
class MediaItem {
  /// URL for a small thumbnail image.
  final String thumbUrl;

  /// URL for a medium resolution preview.
  final String previewUrl;

  /// URL for the full resolution media.
  final String url;

  /// Optional BlurHash for progressive image loading.
  final String? blurHash;

  /// Original media width in pixels.
  final double width;

  /// Original media height in pixels.
  final double height;

  /// Duration for videos. `null` for images.
  final Duration? duration;

  const MediaItem({
    required this.thumbUrl,
    required this.previewUrl,
    required this.url,
    this.blurHash,
    required this.width,
    required this.height,
    this.duration,
  });
}
