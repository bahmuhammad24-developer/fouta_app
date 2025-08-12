import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/features/discovery/discovery_ranking_service.dart';

void main() {
  test('computeScore aggregates values', () {
    final service = DiscoveryRankingService();
    final score = service.computeScore(signals: {'likes': 2}, metadata: {'age': 1});
    expect(score, 3);
  });

  test('rank orders by score', () {
    final service = DiscoveryRankingService();
    final items = ['a', 'b'];
    final ranked = service.rank(items, scoreBuilder: (i) => i == 'a' ? 10 : 1);
    expect(ranked.first, 'a');
  });
}
