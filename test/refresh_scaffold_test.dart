import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/widgets/refresh_scaffold.dart';

void main() {
  testWidgets('pull-to-refresh callback invocation', (tester) async {
    int refreshes = 0;

    await tester.pumpWidget(MaterialApp(
      home: RefreshScaffold(
        onRefresh: () async {
          refreshes++;
        },
        slivers: const [
          SliverToBoxAdapter(child: SizedBox(height: 1000)),
        ],
      ),
    ));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(refreshes, 1);
  });
}
