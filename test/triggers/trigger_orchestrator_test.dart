import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/triggers/trigger_orchestrator.dart';
import 'package:fouta_app/triggers/flags.dart';

void main() {
  test('per-session cap is enforced', () {
    final o = TriggerOrchestrator.instance;
    o.resetSession();

    int fired = 0;
    for (int i = 0; i < AppFlags.capNextUpPerSession + 2; i++) {
      final ok = o.tryFire(
        id: 'next_up_rail',
        enabled: true,
        perSessionCap: AppFlags.capNextUpPerSession,
      );
      if (ok) fired++;
    }
    expect(fired, AppFlags.capNextUpPerSession);
  });

  test('eligibility helper shouldShowNextUp works at 0.9+', () {
    final o = TriggerOrchestrator.instance;
    expect(o.shouldShowNextUp(completedRatio: 0.89), false);
    expect(o.shouldShowNextUp(completedRatio: 0.9), true);
    expect(o.shouldShowNextUp(completedRatio: 1.0), true);
  });
}
