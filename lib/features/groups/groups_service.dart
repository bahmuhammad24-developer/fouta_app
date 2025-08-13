import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../main.dart';
import '../../utils/json_safety.dart';

class Group {
  Group({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    required this.ownerId,
    required this.memberIds,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? coverUrl;
  final String ownerId;
  final List<String> memberIds;
  final DateTime? createdAt;

  factory Group.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Group(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString(),
      coverUrl: data['coverUrl']?.toString(),
      ownerId: data['ownerId']?.toString() ?? '',
      memberIds: asStringList(data['memberIds']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory Group.fromMap(String id, Map<String, dynamic> data) => Group(
        id: id,
        name: data['name']?.toString() ?? '',
        description: data['description']?.toString(),
        coverUrl: data['coverUrl']?.toString(),
        ownerId: data['ownerId']?.toString() ?? '',
        memberIds: asStringList(data['memberIds']),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        if (description != null) 'description': description,
        if (coverUrl != null) 'coverUrl': coverUrl,
        'ownerId': ownerId,
        'memberIds': memberIds,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class GroupsService {
  GroupsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore
      .collection('artifacts')
      .doc(APP_ID)
      .collection('public')
      .doc('data')
      .collection('groups');

  Future<String> createGroup({
    required String name,
    String? description,
    String? coverUrl,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Missing user');
    final doc = await _collection.add({
      'name': name,
      if (description != null) 'description': description,
      if (coverUrl != null) 'coverUrl': coverUrl,
      'ownerId': uid,
      'memberIds': [uid],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Stream<List<Group>> streamGroups() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Group.fromDoc).toList());
  }

  Future<void> joinGroup(String groupId, String userId) async {
    final doc = _collection.doc(groupId);
    await doc.update({'memberIds': FieldValue.arrayUnion([userId])});
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    final doc = _collection.doc(groupId);
    await doc.update({'memberIds': FieldValue.arrayRemove([userId])});
  }

  Future<void> updateGroup(String groupId,
      {String? name, String? description, String? coverUrl}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Missing user');
    final doc = _collection.doc(groupId);
    final snap = await doc.get();
    final data = snap.data();
    if (data == null || data['ownerId']?.toString() != uid) {
      // Only owners can update; TODO: expand roles for moderators.
      throw Exception('Permission denied');
    }
    final update = <String, dynamic>{};
    if (name != null) update['name'] = name;
    if (description != null) update['description'] = description;
    if (coverUrl != null) update['coverUrl'] = coverUrl;
    if (update.isNotEmpty) {
      await doc.update(update);
    }
  }
}
