import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../models/story.dart';
import '../../../models/media_item.dart';
import '../../../utils/firestore_paths.dart';

/// Minimal Firestore backed repository for story operations.
class StoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<StoryItem> publishSlide(
    String userId,
    MediaItem media, {
    String? caption,
  }) async {
    final slideId = const Uuid().v4();
    final ext = media.type == MediaType.video ? 'mp4' : 'jpg';
    final storagePath = 'stories/$userId/$slideId.$ext';
    final storageRef = FirebaseStorage.instance.ref().child(storagePath);

    // Upload the file pointed to by [media.url].
    await storageRef.putFile(File(media.url));
    final downloadUrl = await storageRef.getDownloadURL();

    final doc =
        _firestore.collection(FirestorePaths.stories()).doc(userId);
    await doc.set({
      'userId': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await doc.collection('slides').doc(slideId).set({
      'type': media.type.name,
      'url': downloadUrl,
      if (media.thumbUrl != null) 'thumbUrl': media.thumbUrl,
      if (media.duration != null) 'durationMs': media.duration!.inMilliseconds,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24))),
      if (caption != null) 'caption': caption,
    });

    return StoryItem(
      media: MediaItem(
        id: slideId,
        type: media.type,
        url: downloadUrl,
        thumbUrl: media.thumbUrl,
        duration: media.duration,
      ),
      caption: caption,
    );
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

