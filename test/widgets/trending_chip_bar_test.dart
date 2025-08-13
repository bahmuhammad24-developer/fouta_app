import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/widgets/trending_chip_bar.dart';

void main() {
  testWidgets('TrendingChipBar renders and handles tap', (tester) async {
    String? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrendingChipBar(
            tags: const ['one', 'two'],
            selectedTag: null,
            onSelected: (t) => tapped = t,
          ),
        ),
      ),
    );
    expect(find.text('#one'), findsOneWidget);
    await tester.tap(find.text('#one'));
    expect(tapped, 'one');
  });
}
