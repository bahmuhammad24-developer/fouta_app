import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/screens/ar_camera_screen.dart';

void main() {
  testWidgets('shows flag message when AR_EXPERIMENTAL is false',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: ArCameraScreen(),
    ));

    expect(find.text('AR is experimental—enable flag to try it.'),
        findsOneWidget);
  });
}
