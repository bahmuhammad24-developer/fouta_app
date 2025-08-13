import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/widgets/skeleton.dart';

void main() {
  testWidgets('renders line, rect, and avatar skeletons', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Skeleton.line(width: 100, height: 8),
              Skeleton.rect(width: 80, height: 40, radius: 8),
              Skeleton.avatar(size: 40),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(Skeleton), findsNWidgets(3));
  });
}

