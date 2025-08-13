import 'package:fouta_app/features/discovery/discovery_ranking_v2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('score is monotonic with completion', () {
    const ranking = DiscoveryRankingV2();
    final low = ranking.score(
      completion: 0.1,
      sendDm: 0,
      followAfterView: 0,
      ageHours: 0,
      relationshipProximity: 0,
    );
    final high = ranking.score(
      completion: 0.9,
      sendDm: 0,
      followAfterView: 0,
      ageHours: 0,
      relationshipProximity: 0,
    );
    expect(high, greaterThan(low));
  });

  test('freshness decay drops over time', () {
    const ranking = DiscoveryRankingV2();
    final fresh = ranking.freshnessDecay(0);
    final weekOld = ranking.freshnessDecay(168);
    expect(fresh, greaterThan(weekOld));
    expect(weekOld, closeTo(0.367879, 1e-6));
  });
}
