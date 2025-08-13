import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fouta_app/features/stories/viewer/story_viewer_screen.dart';

void main() {
  testWidgets('story viewer pauses on long press', (tester) async {
    final stories = [
      {
        'id': 's1',
        'mediaUrl': 'https://example.com/img.jpg',
        'mediaType': 'image',
        'overlays': <Map<String, dynamic>>[],
      }
    ];

    await tester.pumpWidget(
      MaterialApp(home: StoryViewerScreen(stories: stories)),
    );

    final progressFinder = find.byKey(const ValueKey('progress_0'));

    await tester.pump(const Duration(milliseconds: 100));
    final before =
        tester.widget<LinearProgressIndicator>(progressFinder).value ?? 0;

    final gesture = await tester.startGesture(const Offset(10, 10));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 200));
    final during =
        tester.widget<LinearProgressIndicator>(progressFinder).value ?? 0;
    expect(during, closeTo(before, 0.001));
    await gesture.up();
  });
}

