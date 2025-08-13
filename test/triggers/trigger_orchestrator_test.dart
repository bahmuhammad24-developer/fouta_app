import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/triggers/trigger_orchestrator.dart';

void main() {
  test('caps block after N hits', () {
    final orch = TriggerOrchestrator.instance;
    expect(orch.canFire('a', cap: 2), true);
    orch.hit('a');
    orch.hit('a');
    expect(orch.canFire('a', cap: 2), false);
  });

  test('eligibility helpers', () {
    expect(shouldShowNextUp(completedRatio: 1), true);
    expect(shouldShowNextUp(completedRatio: 0.1), false);
    expect(shouldShowKeywordChips(dwell: 0.1), true);
    expect(shouldShowKeywordChips(dwell: 1), false);
  });
}
