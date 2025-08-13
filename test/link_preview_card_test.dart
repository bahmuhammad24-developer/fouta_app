import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/features/link_preview/link_preview_card.dart';
import 'package:fouta_app/features/link_preview/link_preview_service.dart';

void main() {
  testWidgets('shows placeholder when image is missing', (tester) async {
    final data = LinkPreviewData(title: 'Example', description: 'Desc');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LinkPreviewCard(data: data),
        ),
      ),
    );
    expect(find.byIcon(Icons.link), findsOneWidget);
  });
}
