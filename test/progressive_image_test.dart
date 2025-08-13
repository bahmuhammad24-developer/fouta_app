import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/widgets/progressive_image.dart';

class _DelayedImageProvider extends ImageProvider<_DelayedImageProvider> {
  _DelayedImageProvider(this.bytes);

  final Uint8List bytes;
  final Completer<void> completer = Completer<void>();

  void complete() => completer.complete();

  @override
  Future<_DelayedImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_DelayedImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _DelayedImageProvider key,
    DecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(_load(decode));
  }

  Future<ImageInfo> _load(DecoderCallback decode) async {
    await completer.future;
    final codec = await decode(bytes);
    final frame = await codec.getNextFrame();
    return ImageInfo(image: frame.image);
  }
}

const List<int> _kTransparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

void main() {
  testWidgets('ProgressiveImage fades from thumb to main image', (tester) async {
    final bytes = Uint8List.fromList(_kTransparentImage);
    final delayed = _DelayedImageProvider(bytes);

    await tester.pumpWidget(
      MaterialApp(
        home: ProgressiveImage(
          imageUrl: 'main.png',
          thumbUrl: 'thumb.png',
          image: delayed,
          thumb: MemoryImage(bytes),
          width: 10,
          height: 10,
        ),
      ),
    );

    final animated = find.byType(AnimatedOpacity);
    expect(tester.widget<AnimatedOpacity>(animated).opacity, 0);

    delayed.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.widget<AnimatedOpacity>(animated).opacity, 1);
  });
}

