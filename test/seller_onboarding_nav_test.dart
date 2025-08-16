import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fouta_app/features/marketplace/create_product_nav.dart';
import 'package:fouta_app/features/marketplace/create_product_screen.dart';
import 'package:fouta_app/features/marketplace/seller_onboarding_screen.dart';
import 'package:fouta_app/features/marketplace/seller_service.dart';

class _FakeSellerService extends SellerService {
  _FakeSellerService(this._isSeller);
  final bool _isSeller;
  @override
  Future<bool> isSeller(String userId) async => _isSeller;
  @override
  Future<void> createSellerProfile({
    required String userId,
    required String displayName,
    String? bio,
  }) async {}
}

void main() {
  testWidgets('non-seller navigates to SellerOnboardingScreen', (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(navigatorKey: navKey, home: const Scaffold()));
    await navigateToCreateProduct(navKey.currentContext!, sellerService: _FakeSellerService(false), userId: 'u1');
    await tester.pumpAndSettle();
    expect(find.byType(SellerOnboardingScreen), findsOneWidget);
  });

  testWidgets('seller navigates to CreateProductScreen', (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(navigatorKey: navKey, home: const Scaffold()));
    await navigateToCreateProduct(navKey.currentContext!, sellerService: _FakeSellerService(true), userId: 'u1');
    await tester.pumpAndSettle();
    expect(find.byType(CreateProductScreen), findsOneWidget);
  });
}
