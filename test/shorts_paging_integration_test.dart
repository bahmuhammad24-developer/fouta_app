import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/features/shorts/shorts_service.dart';
import 'package:fouta_app/screens/shorts_screen.dart';

class _FakeShortsService extends ShortsService {
  final _controller = StreamController<List<Short>>.broadcast();

  @override
  Stream<List<Short>> streamShorts() => _controller.stream;

  void emit(List<Short> items) => _controller.add(items);
}

void main() {
  testWidgets('paging controller loads more once', (tester) async {
    int loads = 0;
    final service = _FakeShortsService();

    await tester.pumpWidget(MaterialApp(
      home: ShortsScreen(
        service: service,
        onLoadMore: () async {
          loads++;
        },
      ),
    ));

    service.emit(List.generate(
      5,
      (i) => Short(id: '$i', authorId: 'a', url: 'u', likeIds: []),
    ));
    await tester.pump();

    final state = tester.state(find.byType(ShortsScreen)) as dynamic;
    final controller = state._paging.scrollController as ScrollController;
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();

    expect(loads, 1);
  });
}

