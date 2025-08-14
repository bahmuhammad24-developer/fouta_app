import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fouta_app/models/story.dart';

/// Abstraction for persisting story views.
abstract class StoryViewsStore {
  Future<void> saveView(String storyId, StoryItem item);
}

/// Firestore-backed implementation of [StoryViewsStore].
class FirestoreStoryViewsStore implements StoryViewsStore {
  final FirebaseFirestore _firestore;
  FirestoreStoryViewsStore({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveView(String storyId, StoryItem item) {
    return _firestore
        .collection('views')
        .doc(storyId)
        .collection('items')
        .doc(item.media.url)
        .set({'seenAt': FieldValue.serverTimestamp()});
  }
}

/// Handles client side state for stories including tracking seen items.
class StoriesService {
  final _seenCache = <String>{};
  final StoryViewsStore _store;

  StoriesService({StoryViewsStore? store})
      : _store = store ?? FirestoreStoryViewsStore();

  bool isItemSeen(StoryItem item) => _seenCache.contains(item.media.url);

  Future<void> markItemSeen(String storyId, StoryItem item) async {
    if (isItemSeen(item)) return;
    _seenCache.add(item.media.url);
    await _store.saveView(storyId, item);
  }
}
