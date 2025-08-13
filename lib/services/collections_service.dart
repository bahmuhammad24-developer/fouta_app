import 'package:cloud_firestore/cloud_firestore.dart';

/// Service layer for managing user saved collections.
class CollectionsService {
  CollectionsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _base(String uid) =>
      _firestore.collection('users/$uid/collections');

  Future<String> createCollection(String uid, String name) async {
    final doc = await _base(uid).add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> addToCollection(String uid, String collectionId, String postId) {
    return _base(uid)
        .doc(collectionId)
        .collection('items')
        .doc(postId)
        .set({'addedAt': FieldValue.serverTimestamp()});
  }

  Future<void> removeFromCollection(
      String uid, String collectionId, String postId) {
    return _base(uid)
        .doc(collectionId)
        .collection('items')
        .doc(postId)
        .delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollections(String uid) {
    return _base(uid).orderBy('createdAt', descending: true).snapshots();
  }
}
