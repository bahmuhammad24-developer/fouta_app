import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/utils/firestore_paths.dart';

/// Handles saving and retrieving post drafts for each user.
class DraftsService {
  DraftsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _draftsRef(String uid) =>
      _firestore
          .collection(FirestorePaths.users())
          .doc(uid)
          .collection('drafts');

  /// Persist [content] and [media] under the given [draftId].
  Future<void> saveDraft(
    String uid,
    String draftId, {
    required String content,
    List<String> media = const [],
  }) async {
    await _draftsRef(uid).doc(draftId).set({
      'content': content,
      'media': media,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Remove the draft identified by [draftId].
  Future<void> deleteDraft(String uid, String draftId) {
    return _draftsRef(uid).doc(draftId).delete();
  }

  /// Fetch all drafts for [uid] ordered by most recent update.
  Future<List<Map<String, dynamic>>> listDrafts(String uid) async {
    final snap = await _draftsRef(uid)
        .orderBy('updatedAt', descending: true)
        .get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .toList();
  }
}
