import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/utils/firestore_paths.dart';

/// Stores scheduled posts for later publication.
class SchedulingService {
  SchedulingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _schedRef(String uid) =>
      _firestore
          .collection(FirestorePaths.users())
          .doc(uid)
          .collection('scheduled');

  /// Schedule [payload] to publish at [publishAt].
  Future<void> schedulePost(
    String uid,
    String id,
    DateTime publishAt,
    Map<String, dynamic> payload,
  ) async {
    await _schedRef(uid).doc(id).set({
      'publishAt': Timestamp.fromDate(publishAt),
      'payload': payload,
    });
  }

  /// Cancel a previously scheduled post.
  Future<void> cancelSchedule(String uid, String id) {
    return _schedRef(uid).doc(id).delete();
  }

  /// List all scheduled posts for [uid].
  Future<List<Map<String, dynamic>>> listScheduled(String uid) async {
    final snap = await _schedRef(uid).orderBy('publishAt').get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .toList();
  }
}
