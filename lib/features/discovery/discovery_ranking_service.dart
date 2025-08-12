/// Provides optional relevance scoring for discovery surfaces without altering
/// existing sort orders. Signals such as likes, comments and watch time are
/// combined with simple content metadata to produce a score that callers may
/// use to reorder results.
///
/// Log messages include timestamps to aid debugging as required by the
/// contributor guide.
class DiscoveryRankingService {
  /// Calculates a relevance score from user [signals] and content [metadata].
  /// Both maps are expected to contain numeric values.
  double computeScore({
    Map<String, num> signals = const {},
    Map<String, num> metadata = const {},
  }) {
    double score = 0;
    signals.forEach((_, value) => score += value.toDouble());
    metadata.forEach((_, value) => score += value.toDouble());
    _log('Computed score: $score');
    return score;
  }

  /// Returns a new list sorted by [computeScore]. Callers may ignore the result
  /// to keep their original ordering intact.
  List<T> rank<T>(List<T> items, {
    double Function(T item)? scoreBuilder,
  }) {
    final scored = <T, double>{};
    for (final item in items) {
      scored[item] = scoreBuilder?.call(item) ?? 0;
    }
    final sorted = items.toList()
      ..sort((a, b) => (scored[b] ?? 0).compareTo(scored[a] ?? 0));
    _log('Ranked ${items.length} items');
    return sorted;
  }

  void _log(String message) {
    final now = DateTime.now().toIso8601String();
    // ignore: avoid_print
    print('[$now][DiscoveryRankingService] $message');
  }
}
