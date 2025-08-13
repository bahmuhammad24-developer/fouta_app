import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/widgets/error_state.dart';
import 'package:fouta_app/widgets/safe_stream_builder.dart';
import 'package:fouta_app/widgets/safe_future_builder.dart';

void main() {
  testWidgets('SafeStreamBuilder builder error renders ErrorState', (tester) async {
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
    expect(tester.takeException(), isNull);
    await controller.close();
  });

  testWidgets('SafeFutureBuilder builder error renders ErrorState', (tester) async {
    final future = Future.value(1);
    await tester.pumpWidget(MaterialApp(
      home: SafeFutureBuilder<int>(
        future: future,
        builder: (context, snapshot) {
          throw Exception('boom');
        },
      ),
    ));

    await tester.pump();

    expect(find.byType(ErrorState), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
