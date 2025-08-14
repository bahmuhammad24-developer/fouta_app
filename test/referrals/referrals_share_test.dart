import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/screens/referrals_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('share button triggers Share.share', (tester) async {
    const channel = MethodChannel('plugins.flutter.io/share');
    String? sharedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'share') {
        sharedText = methodCall.arguments['text'] as String?;
      }
      return null;
    });

    await tester.pumpWidget(const MaterialApp(
      home: ReferralsScreen(userId: 'user-123'),
    ));

    final button = find.bySemanticsLabel('Share referral code');
    expect(button, findsOneWidget);

    await tester.tap(button);
    await tester.pump();

    expect(sharedText, startsWith('Join me on Fouta. Code:'));

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
