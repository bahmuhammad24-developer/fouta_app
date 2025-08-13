import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/features/marketplace/marketplace_service.dart';
import 'package:fouta_app/screens/marketplace_screen.dart';

class _FakeMarketplaceService extends MarketplaceService {
  _FakeMarketplaceService() : super();
  @override
  Stream<List<Product>> streamProducts() => Stream.value(<Product>[]);
}

void main() {
  testWidgets('shows empty state when no products', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MarketplaceScreen(service: _FakeMarketplaceService()),
    ));
    await tester.pump();
    expect(find.text('No listings yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
