enum MediaType { image, video }

/// Canonical media representation used across the app.
class MediaItem {
  final String id;
  final MediaType type;
  final String url;
  final String? thumbUrl;
  final String? previewUrl;
  final int? width;
  final int? height;
  final Duration? duration;

  const MediaItem({
    required this.id,
    required this.type,
    required this.url,
    this.thumbUrl,
    this.previewUrl,
    this.width,
    this.height,
    this.duration,
  });

  /// Aspect ratio helper.
  double get aspectRatio {
    if (width == null || height == null || height == 0) return 1;
    return width! / height!;
  }

  /// Deserialize from Firestore/Map with legacy key fallbacks.
  static MediaItem? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    String _s(Object? v) => (v ?? '').toString();
    int? _i(Object? v) =>
        v is num ? v.toInt() : int.tryParse(v?.toString() ?? '');

    final id = _s(map['id']).isNotEmpty ? _s(map['id']) : _s(map['url']);
    final typeStr = _s(map['type']).toLowerCase();
    final type = typeStr == 'video' ? MediaType.video : MediaType.image;

    // Legacy keys: imageUrl/fileUrl/url
    final url = _s(map['url']).isNotEmpty
        ? _s(map['url'])
        : _s(map['imageUrl']).isNotEmpty
            ? _s(map['imageUrl'])
            : _s(map['fileUrl']);
    if (url.isEmpty) return null; // skip broken items

    final thumb = _s(map['thumbUrl']);
    final preview = _s(map['previewUrl']);

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
      id: id,
      type: type,
      url: url,
      thumbUrl: thumb.isNotEmpty ? thumb : null,
      previewUrl: preview.isNotEmpty ? preview : null,
      width: _i(map['width']),
      height: _i(map['height']),
      duration: dur,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'url': url,
        if (thumbUrl != null) 'thumbUrl': thumbUrl,
        if (previewUrl != null) 'previewUrl': previewUrl,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (duration != null) 'duration': duration!.inMilliseconds,
      };
}

