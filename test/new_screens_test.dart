import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/screens/shorts_screen.dart';
import 'package:fouta_app/screens/marketplace_screen.dart';
import 'package:fouta_app/screens/ar_camera_screen.dart';
import 'package:fouta_app/features/shorts/shorts_service.dart';

class _FakeShortsService extends ShortsService {
  _FakeShortsService() : super();
  @override
  Stream<List<Short>> streamShorts() => Stream.value(<Short>[]);
}

void main() {
  testWidgets('Shorts screen shows empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ShortsScreen(service: _FakeShortsService())),
    );
    await tester.pump();
    expect(find.text('No shorts yet'), findsOneWidget);
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
