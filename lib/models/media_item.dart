/* Clean, compile-safe media model that uses Strings for URLs */
enum MediaType { image, video }

class MediaItem {
  final MediaType type;
  final String thumbUrl;   // small thumbnail for lists
  final String previewUrl; // medium size for viewer prefetch
  final String fullUrl;    // full size
  final double width;
  final double height;
  final Duration? duration; // for videos (null for images)
  final String? blurHash;

  const MediaItem({
    required this.type,
    required this.thumbUrl,
    required this.previewUrl,
    required this.fullUrl,
    required this.width,
    required this.height,
    this.duration,
    this.blurHash,
  });

  double get aspectRatio => (height == 0) ? 1 : width / height;

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    String _s(Object? v, [String fallback = '']) => (v ?? fallback).toString();
    double _d(Object? v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

    final typeStr = _s(map['type']).toLowerCase();
    final mediaType = typeStr == 'video' ? MediaType.video : MediaType.image;

    // Accept either fullUrl/url and previewUrl/thumbUrl gracefully
    final thumb = _s(map['thumbUrl'].toString().isNotEmpty ? map['thumbUrl'] : map['previewUrl']);
    final preview = _s(map['previewUrl'].toString().isNotEmpty ? map['previewUrl'] : map['thumbUrl']);
    final full = _s(map['fullUrl'].toString().isNotEmpty ? map['fullUrl'] : map['url']);

    // duration may be milliseconds, seconds, or already a Duration serialized
    Duration? dur;
    final rawDur = map['duration'];
    if (rawDur is int) {
      dur = Duration(milliseconds: rawDur);
    } else if (rawDur is double) {
      dur = Duration(milliseconds: rawDur.round());
    } else if (rawDur is String) {
      final ms = int.tryParse(rawDur);
      if (ms != null) dur = Duration(milliseconds: ms);
    }

    return MediaItem(
      type: mediaType,
      thumbUrl: thumb,
      previewUrl: preview.isNotEmpty ? preview : thumb,
      fullUrl: full.isNotEmpty ? full : preview.isNotEmpty ? preview : thumb,
      width: _d(map['width']),
      height: _d(map['height']),
      duration: dur,
      blurHash: map['blurHash'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'thumbUrl': thumbUrl,
        'previewUrl': previewUrl,
        'fullUrl': fullUrl,
        'width': width,
        'height': height,
        'duration': duration?.inMilliseconds,
        'blurHash': blurHash,
      };
}
