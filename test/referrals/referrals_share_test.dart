import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/screens/referrals_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('share button invokes shareInvoker', (tester) async {
    String? sharedText;
    final original = shareInvoker;
    shareInvoker = (msg) async {
      sharedText = msg;
    };
    addTearDown(() => shareInvoker = original);

    await tester.pumpWidget(const MaterialApp(
      home: ReferralsScreen(userId: 'user-123'),
    ));

    final button = find.bySemanticsLabel('Share referral code');
    expect(button, findsOneWidget);

    await tester.tap(button);
    await tester.pump();

    expect(sharedText, startsWith('Join me on Fouta. Code:'));
  });
}
