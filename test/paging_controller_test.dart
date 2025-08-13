import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/utils/paging_controller.dart';

void main() {
  testWidgets('threshold triggers only once per page', (tester) async {
    int calls = 0;
    final paging = PagingController(onLoadMore: () async {
      calls++;
    });

    await tester.pumpWidget(MaterialApp(
      home: ListView.builder(
        controller: paging.scrollController,
        itemCount: 20,
        itemBuilder: (_, i) => const SizedBox(height: 100),
      ),
    ));

    paging.scrollController.jumpTo(
      paging.scrollController.position.maxScrollExtent,
    );
    await tester.pump();
    expect(calls, 1);

    paging.scrollController.jumpTo(
      paging.scrollController.position.maxScrollExtent,
    );
    await tester.pump();
    expect(calls, 1);

    paging.reset();
    paging.scrollController.jumpTo(
      paging.scrollController.position.maxScrollExtent,
    );
    await tester.pump();
    expect(calls, 2);

    paging.dispose();
  });
}
