import 'package:flutter_test/flutter_test.dart';

import 'package:fouta_app/features/creation/editor/overlays/overlay_models.dart';

void main() {
  test('overlay models round-trip to map', () {
    final overlays = [
      TextOverlay(
        id: 't1',
        text: 'hi',
        color: 0xFFFFFFFF,
        fontSize: 24,
        dx: 1,
        dy: 2,
        scale: 1,
        rotation: 0,
        opacity: 1,
        z: 0,
      ),
      StickerOverlay(
        id: 's1',
        emoji: '😊',
        dx: 3,
        dy: 4,
        scale: 1.2,
        rotation: 0.1,
        opacity: 0.8,
        z: 1,
      ),
      ShapeOverlay(
        id: 'h1',
        shape: 'rect',
        color: 0xFFFF0000,
        dx: 5,
        dy: 6,
        scale: 0.5,
        rotation: 0,
        opacity: 0.5,
        z: 2,
      ),
    ];

    final maps = overlays.map((o) => o.toMap()).toList();
    final rebuilt = maps.map(OverlayModel.fromMap).toList();
    expect(rebuilt.length, overlays.length);
    for (var i = 0; i < overlays.length; i++) {
      expect(rebuilt[i].toMap(), maps[i]);
    }
  });
}

