import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/widgets/error_state.dart';
import 'package:fouta_app/widgets/safe_stream_builder.dart';

void main() {
  testWidgets('SafeStreamBuilder shows error UI when builder throws',
      (tester) async {
    final controller = StreamController<int>();
    await tester.pumpWidget(MaterialApp(
      home: SafeStreamBuilder<int>(
        stream: controller.stream,
        builder: (context, snapshot) {
          throw Exception('boom');
        },
      ),
    ));

    controller.add(1);
    await tester.pump();

    expect(find.byType(ErrorState), findsOneWidget);
    await controller.close();
  });
}
