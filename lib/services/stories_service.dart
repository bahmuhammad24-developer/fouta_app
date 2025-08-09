import 'dart:async';

import '../models/story.dart';

/// Handles client side state for stories including tracking seen items.
class StoriesService {
  final _seenCache = <String>{};

  bool isItemSeen(StoryItem item) => _seenCache.contains(item.media.url);

  Future<void> markItemSeen(String storyId, StoryItem item) async {
    if (isItemSeen(item)) return;
    _seenCache.add(item.media.url);
    // TODO: Persist to backend e.g. Firestore `views/{userId}` collection.
    await Future<void>.value();
  }
}
