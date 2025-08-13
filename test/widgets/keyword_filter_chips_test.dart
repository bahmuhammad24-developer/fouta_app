import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/widgets/triggers/keyword_filter_chips.dart';

void main() {
  testWidgets('KeywordFilterChips emits selection', (tester) async {
    String? selected;
    await tester.pumpWidget(MaterialApp(
      home: KeywordFilterChips(
        keywords: const ['a', 'b'],
        onSelected: (k) => selected = k,
      ),
    ));
    await tester.tap(find.text('a'));
    expect(selected, 'a');
  });
}
