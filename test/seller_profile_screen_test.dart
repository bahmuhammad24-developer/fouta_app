import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fouta_app/screens/seller_profile_screen.dart';

void main() {
  testWidgets('shows disabled snackbar when payments flag is off', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SellerProfileScreen(sellerId: 'seller1', createdBy: 'user1'),
      ),
    );
    await tester.tap(find.text('Support Creator'));
    await tester.pump();
    expect(find.text('Payments disabled'), findsOneWidget);
  });
}

