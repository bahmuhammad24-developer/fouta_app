import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';

import '../../../models/story.dart';
import '../../../models/media_item.dart';
import '../../../utils/firestore_paths.dart';

/// Minimal Firestore backed repository for story operations.
class StoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<StoryItem> publishSlide(
    String userId,
    File file,
    MediaType type, {
    String? caption,
  }) async {
    final slideId = const Uuid().v4();
    final ext = type == MediaType.video ? 'mp4' : 'jpg';
    final storageRef =
        FirebaseStorage.instance.ref().child('stories/$userId/$slideId.$ext');

    await storageRef.putFile(
      file,
      SettableMetadata(
        contentType: type == MediaType.video ? 'video/mp4' : 'image/jpeg',
      ),
    );
    final downloadUrl = await storageRef.getDownloadURL();

    String? thumbUrl;
    int? durationMs;
    if (type == MediaType.video) {
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      durationMs = controller.value.duration.inMilliseconds;
      await controller.dispose();

      final thumbData = await VideoThumbnail.thumbnailData(
        video: file.path,
        imageFormat: ImageFormat.JPEG,
        quality: 75,
      );
      if (thumbData != null) {
        final thumbRef = FirebaseStorage.instance
            .ref()
            .child('stories/$userId/${slideId}_thumb.jpg');
        await thumbRef.putData(
          thumbData,
          const SettableMetadata(contentType: 'image/jpeg'),
        );
        thumbUrl = await thumbRef.getDownloadURL();
      }
    }

    final doc = _firestore.collection(FirestorePaths.stories()).doc(userId);
    await doc.set({
      'userId': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await doc.collection('slides').doc(slideId).set({
      'type': type.name,
      'url': downloadUrl,
      if (thumbUrl != null) 'thumbUrl': thumbUrl,
      if (durationMs != null) 'durationMs': durationMs,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24))),
      if (caption != null) 'caption': caption,
    });

    debugPrint('[STORY] uploaded: $slideId url=$downloadUrl thumb=$thumbUrl');

    return StoryItem(
      media: MediaItem(
        id: slideId,
        type: type,
        url: downloadUrl,
        thumbUrl: thumbUrl,
        duration: durationMs != null
            ? Duration(milliseconds: durationMs)
            : null,
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

