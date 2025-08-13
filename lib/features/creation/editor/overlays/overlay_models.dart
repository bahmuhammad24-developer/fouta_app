import 'dart:ui';

/// Base type for all overlays placed on the editor canvas.
sealed class OverlayModel {
  OverlayModel({
    required this.id,
    required this.dx,
    required this.dy,
    required this.scale,
    required this.rotation,
    required this.opacity,
    required this.z,
  });

  final String id;
  double dx;
  double dy;
  double scale;
  double rotation;
  double opacity;
  int z;

  Map<String, dynamic> toMap();

  static OverlayModel fromMap(Map<String, dynamic> map) {
    final type = map['type']?.toString();
    switch (type) {
      case 'text':
        return TextOverlay.fromMap(map);
      case 'sticker':
        return StickerOverlay.fromMap(map);
      case 'shape':
        return ShapeOverlay.fromMap(map);
    }
    throw ArgumentError('Unknown overlay type: $type');
  }
}

class TextOverlay extends OverlayModel {
  TextOverlay({
    required super.id,
    required this.text,
    required this.color,
    required this.fontSize,
    required super.dx,
    required super.dy,
    required super.scale,
    required super.rotation,
    required super.opacity,
    required super.z,
  });

  String text;
  int color;
  double fontSize;

  @override
  Map<String, dynamic> toMap() => {
        'type': 'text',
        'id': id,
        'text': text,
        'color': color,
        'fontSize': fontSize,
        'dx': dx,
        'dy': dy,
        'scale': scale,
        'rotation': rotation,
        'opacity': opacity,
        'z': z,
      };

  factory TextOverlay.fromMap(Map<String, dynamic> map) => TextOverlay(
        id: map['id']?.toString() ?? '',
        text: map['text']?.toString() ?? '',
        color: (map['color'] as int?) ?? const Color(0xFFFFFFFF).value,
        fontSize: (map['fontSize'] as num?)?.toDouble() ?? 24.0,
        dx: (map['dx'] as num?)?.toDouble() ?? 0.0,
        dy: (map['dy'] as num?)?.toDouble() ?? 0.0,
        scale: (map['scale'] as num?)?.toDouble() ?? 1.0,
        rotation: (map['rotation'] as num?)?.toDouble() ?? 0.0,
        opacity: (map['opacity'] as num?)?.toDouble() ?? 1.0,
        z: (map['z'] as num?)?.toInt() ?? 0,
      );
}

class StickerOverlay extends OverlayModel {
  StickerOverlay({
    required super.id,
    required this.emoji,
    required super.dx,
    required super.dy,
    required super.scale,
    required super.rotation,
    required super.opacity,
    required super.z,
  });

  String emoji;

  @override
  Map<String, dynamic> toMap() => {
        'type': 'sticker',
        'id': id,
        'emoji': emoji,
        'dx': dx,
        'dy': dy,
        'scale': scale,
        'rotation': rotation,
        'opacity': opacity,
        'z': z,
      };

  factory StickerOverlay.fromMap(Map<String, dynamic> map) => StickerOverlay(
        id: map['id']?.toString() ?? '',
        emoji: map['emoji']?.toString() ?? '',
        dx: (map['dx'] as num?)?.toDouble() ?? 0.0,
        dy: (map['dy'] as num?)?.toDouble() ?? 0.0,
        scale: (map['scale'] as num?)?.toDouble() ?? 1.0,
        rotation: (map['rotation'] as num?)?.toDouble() ?? 0.0,
        opacity: (map['opacity'] as num?)?.toDouble() ?? 1.0,
        z: (map['z'] as num?)?.toInt() ?? 0,
      );
}

class ShapeOverlay extends OverlayModel {
  ShapeOverlay({
    required super.id,
    required this.shape,
    required this.color,
    required super.dx,
    required super.dy,
    required super.scale,
    required super.rotation,
    required super.opacity,
    required super.z,
  });

  String shape; // 'rect' or 'circle'
  int color;

  @override
  Map<String, dynamic> toMap() => {
        'type': 'shape',
        'id': id,
        'shape': shape,
        'color': color,
        'dx': dx,
        'dy': dy,
        'scale': scale,
        'rotation': rotation,
        'opacity': opacity,
        'z': z,
      };

  factory ShapeOverlay.fromMap(Map<String, dynamic> map) => ShapeOverlay(
        id: map['id']?.toString() ?? '',
        shape: map['shape']?.toString() ?? 'rect',
        color: (map['color'] as int?) ?? const Color(0xFFFFFFFF).value,
        dx: (map['dx'] as num?)?.toDouble() ?? 0.0,
        dy: (map['dy'] as num?)?.toDouble() ?? 0.0,
        scale: (map['scale'] as num?)?.toDouble() ?? 1.0,
        rotation: (map['rotation'] as num?)?.toDouble() ?? 0.0,
        opacity: (map['opacity'] as num?)?.toDouble() ?? 1.0,
        z: (map['z'] as num?)?.toInt() ?? 0,
      );
}

