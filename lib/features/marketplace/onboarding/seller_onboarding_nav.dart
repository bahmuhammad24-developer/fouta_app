import 'package:flutter/material.dart';

import 'seller_onboarding_flow.dart';

Future<void> navigateToSellerOnboarding(BuildContext context) async {
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const SellerOnboardingFlow()),
  );
}
