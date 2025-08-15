import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../main.dart';
import '../../utils/json_safety.dart';
import 'models/group_roles.dart';

class Group {
  Group({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    required this.ownerId,
    required this.memberIds,
    required this.roles,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? coverUrl;
  final String ownerId;
  final List<String> memberIds;
  final Map<String, String> roles;
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
      roles: Map<String, String>.from(
          (data['roles'] as Map<String, dynamic>?) ??
              {data['ownerId']?.toString() ?? '': 'owner'}),
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
        roles: Map<String, String>.from(
            (data['roles'] as Map<String, dynamic>?) ??
                {data['ownerId']?.toString() ?? '': 'owner'}),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        if (description != null) 'description': description,
        if (coverUrl != null) 'coverUrl': coverUrl,
        'ownerId': ownerId,
        'memberIds': memberIds,
        'roles': roles,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class GroupsService {
  GroupsService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

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
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Missing user');
    final doc = await _collection.add({
      'name': name,
      if (description != null) 'description': description,
      if (coverUrl != null) 'coverUrl': coverUrl,
      'ownerId': uid,
      'memberIds': [uid],
      'roles': {uid: 'owner'},
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

  Future<void> addModerator(String groupId, String userId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Missing user');
    final doc = _collection.doc(groupId);
    final snap = await doc.get();
    final data = snap.data();
    if (data == null) throw Exception('Group not found');
    final roles = Map<String, dynamic>.from(data['roles'] ?? {});
    final members = List<String>.from(data['memberIds'] ?? []);
    if (roles[uid] != 'owner') throw Exception('Permission denied');
    if (!members.contains(userId)) throw Exception('User not a member');
    await doc.update({'roles.$userId': 'moderator'});
  }

  Future<void> removeModerator(String groupId, String userId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Missing user');
    final doc = _collection.doc(groupId);
    final snap = await doc.get();
    final data = snap.data();
    if (data == null) throw Exception('Group not found');
    final roles = Map<String, dynamic>.from(data['roles'] ?? {});
    if (roles[uid] != 'owner') throw Exception('Permission denied');
    await doc.update({'roles.$userId': FieldValue.delete()});
  }

  Future<void> updateGroup(String groupId,
      {String? name,
      String? description,
      String? coverUrl,
      String? newOwnerId}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Missing user');
    final doc = _collection.doc(groupId);
    final snap = await doc.get();
    final data = snap.data();
    if (data == null) throw Exception('Group not found');
    final roles = Map<String, dynamic>.from(data['roles'] ?? {});
    final role = roles[uid];
    final isOwner = role == 'owner';
    final isModerator = role == 'moderator';
    if (!isOwner && !isModerator) throw Exception('Permission denied');
    if (!isOwner && newOwnerId != null) {
      throw Exception('Only owners can transfer ownership');
    }
    final update = <String, dynamic>{};
    if (name != null) update['name'] = name;
    if (description != null) update['description'] = description;
    if (coverUrl != null) update['coverUrl'] = coverUrl;
    if (isOwner && newOwnerId != null) {
      final members = List<String>.from(data['memberIds'] ?? []);
      if (!members.contains(newOwnerId)) {
        throw Exception('New owner must be a member');
      }
      update['ownerId'] = newOwnerId;
      update['roles.$newOwnerId'] = 'owner';
      update['roles.$uid'] = FieldValue.delete();
    }
    if (update.isNotEmpty) await doc.update(update);
  }
}

Future<void> addModerator(String groupId, String uid) async {
  // TODO: implement write to roles map; for now just stub to keep PR small
  GroupRole.moderator;
}

Future<void> removeModerator(String groupId, String uid) async {
  // TODO: implement write to roles map; for now just stub to keep PR small
  GroupRole.moderator;
}
