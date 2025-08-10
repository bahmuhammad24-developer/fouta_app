import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/story.dart';
import '../../../models/media_item.dart';

/// Minimal Firestore backed repository for story operations.
class StoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> publishSlide(
    String userId,
    MediaItem media, {
    String? caption,
  }) async {
    final doc = _firestore.collection('stories').doc(userId);
    await doc.set({
      'userId': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await doc.collection('slides').add({
      'type': media.type.name,
      'url': media.url,
      'thumbUrl': media.thumbUrl,
      'durationMs': media.duration?.inMilliseconds,
      'createdAt': FieldValue.serverTimestamp(),
      'caption': caption,
    });
  }

  Future<List<Story>> fetchStoriesFeed() async {
    // Simplified client-side filter; real implementation would handle expiry etc.
    final query = await _firestore.collection('stories').get();
    return query.docs.map((d) {
      return Story(
        id: d.id,
        authorId: d['userId'] ?? d.id,
        postedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        expiresAt:
            DateTime.now().add(const Duration(hours: 24)), // naive placeholder
      );
    }).toList();
  }

  Future<void> markViewed(String userId, String slideId) async {
    await _firestore
        .collection('stories')
        .doc(userId)
        .collection('slides')
        .doc(slideId)
        .set({
      'viewedBy': FieldValue.arrayUnion([userId])
    }, SetOptions(merge: true));
  }
}

