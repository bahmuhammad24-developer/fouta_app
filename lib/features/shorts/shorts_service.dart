import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../main.dart';
import '../../utils/json_safety.dart';

class Short {
  Short({
    required this.id,
    required this.authorId,
    required this.url,
    this.aspectRatio,
    this.duration,
    required this.likeIds,
    this.createdAt,
  });

  final String id;
  final String authorId;
  final String url;
  final double? aspectRatio;
  final double? duration;
  final List<String> likeIds;
  final DateTime? createdAt;

  factory Short.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Short(
      id: doc.id,
      authorId: data['authorId']?.toString() ?? '',
      url: data['url']?.toString() ?? '',
      aspectRatio: asDoubleOrNull(data['aspectRatio']),
      duration: asDoubleOrNull(data['duration']),
      likeIds: asStringList(data['likeIds']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class ShortsService {
  ShortsService({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore
      .collection('artifacts')
      .doc(APP_ID)
      .collection('public')
      .doc('data')
      .collection('shorts');

  Future<void> uploadShort(XFile file, {String? soundRef}) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final ref =
        _storage.ref('artifacts/$APP_ID/public/data/shorts/${file.name}');
    await ref.putData(await file.readAsBytes());
    final url = await ref.getDownloadURL();
    await _collection.add({
      'authorId': userId,
      'url': url,
      if (soundRef != null) 'soundRef': soundRef,
      'likeIds': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Short>> streamShorts() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Short.fromDoc).toList());
  }

  Future<void> likeShort(String id, String userId) => _collection.doc(id).update({
        'likeIds': FieldValue.arrayUnion([userId]),
      });

  Future<void> unlikeShort(String id, String userId) => _collection.doc(id).update({
        'likeIds': FieldValue.arrayRemove([userId]),
      });
}
