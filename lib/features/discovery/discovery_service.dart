import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/utils/firestore_paths.dart';
import 'package:fouta_app/main.dart';

/// Handles content discovery, hashtags, and personalized feed ranking.
class DiscoveryService {
  final List<String> _posts = [];
  final Map<String, int> _tagCounts = {};
  static final _tagRegex = RegExp(r'#(\w+)');

  /// Extracts unique hashtag strings without the leading `#`.
  static List<String> extractHashtags(String content) {
    return _tagRegex
        .allMatches(content)
        .map((m) => m.group(1)!.toLowerCase())
        .toSet()
        .toList();
  }

  /// Update the aggregate hashtag counts under
  /// `artifacts/$APP_ID/public/data/hashtags/{tag}`.
  static Future<void> updateHashtagAggregates(
    FirebaseFirestore firestore,
    List<String> newTags, {
    List<String> oldTags = const [],
  }) async {
    final hashtagsColl =
        firestore.collection(FirestorePaths.hashtags(APP_ID));
    final added = newTags.toSet();
    final removed = oldTags.where((t) => !added.contains(t)).toSet();
    final now = FieldValue.serverTimestamp();

    await firestore.runTransaction((tx) async {
      for (final tag in added) {
        final ref = hashtagsColl.doc(tag);
        final snap = await tx.get(ref);
        final current = (snap.data()?['count'] ?? 0) as int;
        tx.set(ref, {
          'count': current + 1,
          'lastUsedAt': now,
        }, SetOptions(merge: true));
      }
      for (final tag in removed) {
        final ref = hashtagsColl.doc(tag);
        final snap = await tx.get(ref);
        final current = (snap.data()?['count'] ?? 0) as int;
        tx.set(ref, {
          'count': current > 0 ? current - 1 : 0,
        }, SetOptions(merge: true));
      }
    });
  }

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
