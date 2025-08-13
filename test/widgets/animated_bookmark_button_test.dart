import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fouta_app/widgets/animated_bookmark_button.dart';

void main() {
  testWidgets('AnimatedBookmarkButton toggles and shows checkmark', (tester) async {
    var saved = false;
    await tester.pumpWidget(MaterialApp(
      home: AnimatedBookmarkButton(
        isSaved: saved,
        onChanged: (v) => saved = v,
      ),
    ));

    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

    await tester.tap(find.byType(AnimatedBookmarkButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(saved, isTrue);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });
}
