import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/features/discovery/discovery_ranking_v2.dart';

void main() {
  test('items are ordered by score descending', () {
    final r = DiscoveryRankingV2();

    final a = {'name': 'A'};
    final b = {'name': 'B'};

    final ranked = r.rank<Map<String, Object?>>( 
      [a, b],
      (m) => m['name'] == 'A'
          ? const RankingSignals(
              completion: 0.2,
              sendDm: 0.0,
              followAfterView: 0.0,
              ageHours: 10,
              relationshipProximity: 0.0,
            )
          : const RankingSignals(
              completion: 0.8,
              sendDm: 1.0,
              followAfterView: 0.5,
              ageHours: 1,
              relationshipProximity: 0.2,
            ),
    );

    expect(ranked.first['name'], 'B');
  });
}
