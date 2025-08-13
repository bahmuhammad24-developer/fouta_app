// lib/features/discovery/discovery_ranking_v2.dart
import 'dart:math' as math;

/// A simple, pluggable ranker that scores items using high-value engagement
/// signals. Keep V1 intact; gate usage via AppFlags.feedRanking == 'v2'.
///
/// Score := w1*completion + w2*sendDm + w3*followAfterView
///          + w4*freshnessDecay + w5*relationshipProximity
///
/// - completion: 0.0..1.0 (viewed / duration)
//  - sendDm: 0 or 1 (or probability 0..1 if you have it)
/// - followAfterView: 0 or 1 (or probability 0..1)
/// - freshnessDecay: exp(-ageHours / 168)  // 7-day half-life-ish
/// - relationshipProximity: 0.0..1.0 (mutual interactions heuristic)
class DiscoveryRankingV2 {
  final double wCompletion;
  final double wSendDm;
  final double wFollowAfterView;
  final double wFreshness;
  final double wProximity;

  const DiscoveryRankingV2({
    this.wCompletion = 0.40,
    this.wSendDm = 0.25,
    this.wFollowAfterView = 0.15,
    this.wFreshness = 0.15,
    this.wProximity = 0.05,
  });

  /// Compute a score for one item from primitive signals.
  double score({
    required double completion, // 0..1
    required double sendDm, // 0..1
    required double followAfterView, // 0..1
    required double ageHours, // >= 0
    required double relationshipProximity, // 0..1
  }) {
    final freshnessDecay = math.exp(-ageHours / 168.0);
    return (wCompletion * _clamp01(completion)) +
        (wSendDm * _clamp01(sendDm)) +
        (wFollowAfterView * _clamp01(followAfterView)) +
        (wFreshness * _clamp01(freshnessDecay)) +
        (wProximity * _clamp01(relationshipProximity));
  }

  /// Sorts [items] descending by score. You pass a signal extractor to avoid
  /// depending on your concrete models here.
  ///
  /// Example extractor:
  ///   (post) => RankingSignals(
  ///     completion: post.watchCompletion,
  ///     sendDm: post.sentViaDm ? 1 : 0,
  ///     followAfterView: post.followedAfterView ? 1 : 0,
  ///     ageHours: post.ageHours,
  ///     relationshipProximity: post.proximityScore,
  ///   );
  List<T> rank<T>(
    List<T> items,
    RankingSignals Function(T item) signalsFor,
  ) {
    final scored = <_Scored<T>>[];
    for (final item in items) {
      final s = signalsFor(item);
      final sc = score(
        completion: s.completion,
        sendDm: s.sendDm,
        followAfterView: s.followAfterView,
        ageHours: s.ageHours,
        relationshipProximity: s.relationshipProximity,
      );
      scored.add(_Scored(item, sc));
    }
    scored.sort((a, b) => b.score.compareTo(a.score)); // high → low
    return scored.map((e) => e.item).toList(growable: false);
  }

  static double _clamp01(double v) => v.isNaN ? 0.0 : v.clamp(0.0, 1.0);
}

class RankingSignals {
  final double completion;
  final double sendDm;
  final double followAfterView;
  final double ageHours;
  final double relationshipProximity;

  const RankingSignals({
    required this.completion,
    required this.sendDm,
    required this.followAfterView,
    required this.ageHours,
    required this.relationshipProximity,
  });
}

class _Scored<T> {
  final T item;
  final double score;
  _Scored(this.item, this.score);
}
