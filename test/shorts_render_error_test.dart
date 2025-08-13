import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/screens/shorts_screen.dart';
import 'package:fouta_app/features/shorts/shorts_service.dart';

class _ErrorShortsService extends ShortsService {
  _ErrorShortsService() : super();
  @override
  Stream<List<Short>> streamShorts() {
    return Stream.value([
      Short(
        id: '1',
        authorId: 'a',
        url: '',
        aspectRatio: 0,
        duration: null,
        likeIds: const [],
      ),
    ]);
  }
}

void main() {
  testWidgets('renders failure tile when builder throws', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ShortsScreen(service: _ErrorShortsService())),
    );
    await tester.pump();
    expect(find.text('failed to render'), findsOneWidget);
  });
}
