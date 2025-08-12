import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/screens/shorts_screen.dart';
import 'package:fouta_app/features/shorts/shorts_service.dart';

class _FakeShortsService extends ShortsService {
  _FakeShortsService() : super(firestore: null);

  @override
  Stream<List<Map<String, dynamic>>> fetchShorts() {
    return Stream.value([
      {'url': null},
      {'url': null},
    ]);
  }
}

void main() {
  testWidgets('Shorts screen scrolls vertically', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ShortsScreen(service: _FakeShortsService()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PageView), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(0, -300), 1000);
    await tester.pumpAndSettle();
    // No crash indicates scrolling works.
  });
}
