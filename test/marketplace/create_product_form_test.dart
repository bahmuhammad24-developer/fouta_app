import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:fouta_app/features/marketplace/create_product_screen.dart';

void main() {
  testWidgets('Create Product form validates required fields', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreateProductScreen()));

    // Submit without input
    await tester.tap(find.text('Create Listing'));
    await tester.pumpAndSettle();

    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Price is required'), findsOneWidget);

    // Fill valid values
    await tester.enterText(find.byType(TextFormField).first, 'Nice Lamp');
    await tester.enterText(find.byType(TextFormField).at(1), '49.99');
    await tester.tap(find.text('Create Listing'));
    await tester.pump(); // allow async to start
  });
}
