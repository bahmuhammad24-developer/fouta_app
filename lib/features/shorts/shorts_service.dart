import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles uploading and retrieving short form videos (~60s).
class ShortsService {
  ShortsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> uploadShort(String userId, Map<String, dynamic> data) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('shorts').add(data);
    _log('Uploaded short for $userId');
  }

  Stream<List<Map<String, dynamic>>> fetchShorts() {
    _log('Fetching shorts');
    return _firestore
        .collection('shorts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  void _log(String message) {
    final now = DateTime.now().toIso8601String();
    // ignore: avoid_print
    print('[$now][ShortsService] $message');
  }
}
