/// Handles content discovery, hashtags, and personalized feed ranking.
class DiscoveryService {
  final List<String> _posts = [];
  final Map<String, int> _tagCounts = {};

  /// Index a piece of [content] for search and trending hashtag tracking.
  void indexPost(String content) {
    _posts.add(content);
    final regex = RegExp(r'#(\w+)');
    for (final match in regex.allMatches(content.toLowerCase())) {
      final tag = match.group(1)!;
      _tagCounts[tag] = (_tagCounts[tag] ?? 0) + 1;
    }
  }

  /// Simple full text search over previously indexed posts.
  List<String> search(String query) {
    final q = query.toLowerCase();
    return _posts.where((p) => p.toLowerCase().contains(q)).toList();
  }

  /// Returns the most frequently used hashtags in descending order.
  List<String> trendingTags({int limit = 10}) {
    final entries = _tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).map((e) => '#${e.key}').toList();
  }

  /// Naive recommendation engine that suggests posts containing the top tag.
  List<String> recommendedPosts() {
    final trending = trendingTags(limit: 1);
    if (trending.isEmpty) return [];
    final tag = trending.first.substring(1); // remove '#'
    return _posts
        .where((p) => p.toLowerCase().contains('#$tag'))
        .toList();
  }
}
