import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/utils/async_guard.dart';

class _Dummy extends StatefulWidget {
  const _Dummy({super.key});

  @override
  _DummyState createState() => _DummyState();
}

class _DummyState extends State<_Dummy> {
  int count = 0;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  testWidgets('mountedSetState no-op when unmounted', (tester) async {
    await tester.pumpWidget(const _Dummy());
    final _DummyState state = tester.state(find.byType(_Dummy));
    await tester.pumpWidget(const SizedBox());
    mountedSetState(state, () {
      state.count++;
    });
    expect(state.count, 0);
  });

  test('guardAsync catches and surfaces errors', () async {
    Object? seen;
    Future<void> run() => guardAsync<void>(() async {
          throw StateError('boom');
        }, onError: (e, st) {
          seen = e;
        });

    await expectLater(run(), throwsA(isA<StateError>()));
    expect(seen, isA<StateError>());
  });
}
