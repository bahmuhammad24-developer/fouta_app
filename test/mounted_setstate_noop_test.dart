import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/utils/async_guard.dart';
import 'package:flutter/material.dart';

class _Dummy extends StatefulWidget {
  const _Dummy({super.key});

  @override
  State<_Dummy> createState() => _DummyState();
}

class _DummyState extends State<_Dummy> {
  int count = 0;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  testWidgets('mountedSetState is no-op after dispose', (tester) async {
    await tester.pumpWidget(const _Dummy());
    final _DummyState state = tester.state(find.byType(_Dummy));
    await tester.pumpWidget(const SizedBox());
    mountedSetState(state, () {
      state.count++;
    });
    expect(state.count, 0);
  });
}
