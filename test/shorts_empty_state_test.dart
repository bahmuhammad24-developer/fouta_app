import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/features/shorts/shorts_service.dart';
import 'package:fouta_app/screens/shorts_screen.dart';

class _FakeShortsService extends ShortsService {
  _FakeShortsService() : super();
  @override
  Stream<List<Short>> streamShorts() => Stream.value(<Short>[]);
}

void main() {
  testWidgets('shows empty state when no shorts', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ShortsScreen(service: _FakeShortsService()),
    ));
    await tester.pump();
    expect(find.text('No shorts yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
