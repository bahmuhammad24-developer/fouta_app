import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fouta_app/screens/marketplace_filters_sheet.dart';

void main() {
  testWidgets('applies filters', (tester) async {
    MarketplaceFilters? result;
    await tester.pumpWidget(
      MaterialApp(
        home: MarketplaceFiltersSheet(
          initial: MarketplaceFilters(),
          onApply: (f) => result = f,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).at(0), 'shoes');
    await tester.enterText(find.byType(TextField).at(1), 'fashion');
    await tester.enterText(find.byType(TextField).at(2), '10');
    await tester.enterText(find.byType(TextField).at(3), '100');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(result?.query, 'shoes');
    expect(result?.category, 'fashion');
    expect(result?.minPrice, 10);
    expect(result?.maxPrice, 100);
  });
}
