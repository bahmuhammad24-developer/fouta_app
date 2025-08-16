import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for seller profile management.
class SellerService {
  SellerService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('sellers');

  /// Whether a seller profile exists for the given [userId].
  Future<bool> isSeller(String userId) async {
    final doc = await _collection.doc(userId).get();
    return doc.exists;
  }

  /// Create or update a seller profile.
  Future<void> createSellerProfile({
    required String userId,
    required String displayName,
    String? bio,
  }) async {
    await _collection.doc(userId).set({
      'displayName': displayName,
      if (bio != null && bio.isNotEmpty) 'bio': bio,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
