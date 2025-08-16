import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/features/marketplace/marketplace_service.dart';
import 'package:fouta_app/features/marketplace/product_card.dart';

void main() {
  testWidgets('focused product card shows focus highlight', (tester) async {
    final product = Product(
      id: '1',
      sellerId: 'seller',
      imageUris: const [],
      title: 'Test',
      category: 'c',
      priceAmount: 1,
      priceCurrency: 'USD',
      favoriteUserIds: const [],
    );

    await tester.pumpWidget(MaterialApp(home: ProductCard(product: product)));

    final inkFinder = find.descendant(
      of: find.byType(ProductCard),
      matching: find.byType(InkWell),
    );
    final element = tester.element(inkFinder);
    final focusNode = Focus.of(element);
    focusNode.requestFocus();
    await tester.pumpAndSettle();

    final material = Material.of(element);
    expect(material.debugInkFeatures.any((f) => f is InkHighlight), isTrue);
  });
}
