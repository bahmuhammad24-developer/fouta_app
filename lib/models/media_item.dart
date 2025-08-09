
import 'package:meta/meta.dart';

/// Describes an individual media item attached to a post.
@immutable
class MediaItem {
  const MediaItem({
    required this.type,
    required this.thumbUrl,
    required this.previewUrl,
    required this.fullUrl,
    required this.width,
    required this.height,
    this.duration,
    this.blurHash,
    this.captionUrl,
  });

  final MediaType type;
  final Uri thumbUrl;
  final Uri previewUrl;
  final Uri fullUrl;
  final double width;
  final double height;
  final double? duration;
  final String? blurHash;
  final Uri? captionUrl;

  double get aspectRatio => width == 0 ? 1 : width / height;

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      type: MediaType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'image'),
        orElse: () => MediaType.image,
      ),
      thumbUrl: Uri.parse((map['thumbUrl'] ?? map['url'] ?? '').toString()),
      previewUrl: Uri.parse((map['previewUrl'] ?? map['url'] ?? '').toString()),
      fullUrl: Uri.parse((map['fullUrl'] ?? map['url'] ?? '').toString()),
      width: _extractWidth(map),
      height: _extractHeight(map),
      duration: (map['duration'] as num?)?.toDouble(),
      blurHash: map['blurHash'] as String?,
      captionUrl:
          map['captionUrl'] != null ? Uri.parse(map['captionUrl']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'thumbUrl': thumbUrl.toString(),
        'previewUrl': previewUrl.toString(),
        'fullUrl': fullUrl.toString(),
        'width': width,
        'height': height,
        if (duration != null) 'duration': duration,
        if (blurHash != null) 'blurHash': blurHash,
        if (captionUrl != null) 'captionUrl': captionUrl.toString(),
      };
}

enum MediaType { image, video }

double _extractWidth(Map<String, dynamic> map) {
  final num? width = map['width'] as num?;
  if (width != null) return width.toDouble();
  final num? aspect = map['aspectRatio'] as num?;
  return aspect?.toDouble() ?? 1;
}

double _extractHeight(Map<String, dynamic> map) {
  final num? height = map['height'] as num?;
  return height?.toDouble() ?? 1;


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
