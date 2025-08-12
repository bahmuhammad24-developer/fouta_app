/// Coordinates reporting, blocking, and automated review queues.
import 'package:cloud_firestore/cloud_firestore.dart';

class ModerationService {
  ModerationService({FirebaseFirestore? firestore, required this.appId})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String appId;

  /// Submit a report for a post. Stores the report under
  /// `artifacts/<appId>/public/data/post_reports` for follow‑up moderation.
  Future<void> reportPost({
    required String postId,
    required String reporterId,
    required String authorId,
    required String reason,
  }) async {
    await _firestore
        .collection('artifacts/$appId/public/data/post_reports')
        .add({
      'postId': postId,
      'reporterId': reporterId,
      'authorId': authorId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reportComment({
    required String commentId,
    required String reporterId,
    required String authorId,
    required String reason,
  }) async {
    await _firestore.collection('artifacts/$appId/public/data/comment_reports').add({
      'commentId': commentId,
      'reporterId': reporterId,
      'authorId': authorId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> blockUser(String userId, String targetId) async {
    await _firestore.collection('users').doc(userId).collection('blocks').doc(targetId).set({
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblockUser(String userId, String targetId) async {
    await _firestore.collection('users').doc(userId).collection('blocks').doc(targetId).delete();
  }
}
