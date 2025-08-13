// lib/features/discovery/discovery_ranking_v2.dart
import 'dart:math' as math;

/// Weighted scoring model for discovery ranking v2.
class DiscoveryRankingV2 {
  const DiscoveryRankingV2({
    this.w1 = 0.40,
    this.w2 = 0.25,
    this.w3 = 0.15,
    this.w4 = 0.15,
    this.w5 = 0.05,
  });

  final double w1;
  final double w2;
  final double w3;
  final double w4;
  final double w5;

  double freshnessDecay(double ageHours) {
    return math.exp(-ageHours / 168);
  }

  double score({
    required double completion,
    required double sendDm,
    required double followAfterView,
    required double ageHours,
    required double relationshipProximity,
  }) {
    return w1 * completion +
        w2 * sendDm +
        w3 * followAfterView +
        w4 * freshnessDecay(ageHours) +
        w5 * relationshipProximity;
  }
}
