import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fouta_app/widgets/animated_like_button.dart';

void main() {
  testWidgets('AnimatedLikeButton toggles and animates', (tester) async {
    var liked = false;
    await tester.pumpWidget(MaterialApp(
      home: AnimatedLikeButton(
        isLiked: liked,
        onChanged: (v) => liked = v,
      ),
    ));

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);

    await tester.tap(find.byType(AnimatedLikeButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(liked, isTrue);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });
}
