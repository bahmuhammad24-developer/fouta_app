import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/screens/referrals_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

class _MockSharePlatform extends SharePlatform {
  String? sharedText;
  bool shareCalled = false;

  @override
  Future<void> share(
    String text, {
    String? subject,
    Rect? sharePositionOrigin,
    ShareResultCallback? resultCallback,
  }) async {
    shareCalled = true;
    sharedText = text;
  }
}

void main() {
  testWidgets('share button invokes Share.share', (tester) async {
    final mockPlatform = _MockSharePlatform();
    SharePlatform.instance = mockPlatform;

    await tester.pumpWidget(const MaterialApp(
      home: ReferralsScreen(userId: 'u1'),
    ));

    await tester.tap(find.bySemanticsLabel('Share referral code'));
    await tester.pump();

    expect(mockPlatform.shareCalled, isTrue);
    expect(mockPlatform.sharedText, startsWith('Join me on Fouta. Code:'));
  });
}

