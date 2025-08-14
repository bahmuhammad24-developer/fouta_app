import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'
    show FirebaseStorage, SettableMetadata;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';

import '../../../devtools/diagnostics_panel.dart';

import 'package:fouta_app/models/story.dart';
import 'package:fouta_app/models/media_item.dart';
import '../../../utils/firestore_paths.dart';

/// Minimal Firestore backed repository for story operations.
class StoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<StoryItem> publishSlide(
    String userId,
    XFile file,
    MediaType type, {
    String? caption,
  }) async {
    final slideId = const Uuid().v4();
    final ext = type == MediaType.video ? 'mp4' : 'jpg';
    final storageRef =
        FirebaseStorage.instance.ref().child('stories/$userId/$slideId.$ext');

    final isContent = file.path.startsWith('content://');
    final metadata = SettableMetadata(
        contentType: type == MediaType.video ? 'video/mp4' : 'image/jpeg');
    if (isContent) {
      final bytes = await file.readAsBytes();
      await storageRef.putData(bytes, metadata);
    } else {
      await storageRef.putFile(File(file.path), metadata);
    }
    final downloadUrl = await storageRef.getDownloadURL();

    String? thumbUrl;
    int? durationMs;
    if (type == MediaType.video) {
      final controller = isContent
          ? VideoPlayerController.contentUri(Uri.parse(file.path))
          : VideoPlayerController.file(File(file.path));
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
          SettableMetadata(contentType: 'image/jpeg'),
        );
        thumbUrl = await thumbRef.getDownloadURL();
      }
    }

    final batch = _firestore.batch();
    final ownerRef =
        _firestore.collection(FirestorePaths.stories()).doc(userId);
    batch.set(ownerRef, {
      'userId': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    final slideRef = ownerRef.collection('slides').doc(slideId);
    final expiresAt =
        Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24)));
    batch.set(slideRef, {
      'type': type.name,
      'url': downloadUrl,
      'thumbUrl': thumbUrl,
      'durationMs': durationMs,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': expiresAt,
      if (caption != null) 'caption': caption,
    });
    await batch.commit();

    debugPrint('[STORY] uploaded: $slideId url=$downloadUrl thumb=$thumbUrl');

    final item = StoryItem(
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
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
    StoryDiagnostics.instance.lastPublish = PublishResult(
      type: type.name,
      url: downloadUrl,
      thumbUrl: thumbUrl,
      durationMs: durationMs,
    );
    return item;
  }

  Future<List<Story>> fetchStoriesFeed() async {
    // Simplified client-side filter; real implementation would handle expiry etc.
    final query = await _firestore.collection('stories').get();
    return query.docs.map((d) {
      return Story(
        id: d.id,
        authorId: d['userId'] ?? d.id,
        userName: d['userName'] as String?,
        userImageUrl: d['userImageUrl'] as String?,
        postedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        expiresAt:
            DateTime.now().add(const Duration(hours: 24)), // naive placeholder
      );
    }).toList();
  }

  Future<void> markViewed({
    required String ownerId,
    required String slideId,
    required String uid,
  }) async {
    final slideRef = _firestore
        .doc('${FirestorePaths.stories()}/$ownerId/slides/$slideId');
    final ownerRef = _firestore.doc('${FirestorePaths.stories()}/$ownerId');

    final batch = _firestore.batch();
    batch.update(slideRef, {'viewers': FieldValue.arrayUnion([uid])});
    batch.set(ownerRef, {
      'viewedBy': FieldValue.arrayUnion([uid])
    }, SetOptions(merge: true));
    await batch.commit();
  }
}

