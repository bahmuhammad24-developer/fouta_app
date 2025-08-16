import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'create_product_screen.dart';
import 'seller_onboarding_screen.dart';
import 'seller_service.dart';

/// Navigate to either seller onboarding or product creation depending on
/// whether the current user is already a seller.
Future<void> navigateToCreateProduct(
  BuildContext context, {
  SellerService? sellerService,
  String? userId,
}) async {
  final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  final svc = sellerService ?? SellerService();
  final isSeller = await svc.isSeller(uid);
  final Widget screen = isSeller
      ? const CreateProductScreen()
      : const SellerOnboardingScreen();
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => screen),
  );
}
