import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fouta_app/widgets/reaction_tray.dart';

void main() {
  testWidgets('ReactionTray returns selection', (tester) async {
    ReactionType? selected;
    await tester.pumpWidget(MaterialApp(
      home: ReactionTray(onReactionSelected: (r) => selected = r),
    ));

    await tester.longPress(find.byType(ReactionTray));
    await tester.pumpAndSettle();

    await tester.tap(find.text('❤️'));
    await tester.pump();

    expect(selected, ReactionType.love);
  });
}
