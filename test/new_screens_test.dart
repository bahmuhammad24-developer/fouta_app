import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/screens/shorts_screen.dart';
import 'package:fouta_app/screens/marketplace_screen.dart';
import 'package:fouta_app/screens/ar_camera_screen.dart';

void main() {
  testWidgets('Shorts screen shows placeholder', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShortsScreen()));
    expect(find.text('Short-form videos coming soon.'), findsOneWidget);
  });

  testWidgets('Marketplace screen shows placeholder', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MarketplaceScreen()));
    expect(find.text('Marketplace listings will appear here.'), findsOneWidget);
  });

  testWidgets('AR Camera screen shows placeholder', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ArCameraScreen()));
    expect(find.text('AR effects will be available soon.'), findsOneWidget);
  });
}
