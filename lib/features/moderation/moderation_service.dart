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
}
