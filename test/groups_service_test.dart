import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/fake.dart';

import 'package:fouta_app/features/groups/groups_service.dart';
import 'package:fouta_app/main.dart';

class _FakeAuth extends Fake implements FirebaseAuth {
  _FakeAuth(this._uid);
  final String _uid;
  @override
  User? get currentUser => _FakeUser(_uid);
}

class _FakeUser extends Fake implements User {
  _FakeUser(this.uid);
  @override
  final String uid;
}

void main() {
  group('GroupsService roles', () {
    late FakeFirebaseFirestore firestore;
    late CollectionReference<Map<String, dynamic>> groups;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      groups = firestore
          .collection('artifacts')
          .doc(APP_ID)
          .collection('public')
          .doc('data')
          .collection('groups');
    });

    test('createGroup assigns creator as owner', () async {
      final service = GroupsService(firestore: firestore, auth: _FakeAuth('owner'));
      final id = await service.createGroup(name: 'test');
      final snap = await groups.doc(id).get();
      expect(snap.data()!['roles']['owner'], 'owner');
    });

    test('owner can add and remove moderators', () async {
      final service = GroupsService(firestore: firestore, auth: _FakeAuth('owner'));
      final id = await service.createGroup(name: 'test');
      await service.addModerator(id, 'mod');
      var snap = await groups.doc(id).get();
      expect(snap.data()!['roles']['mod'], 'moderator');
      await service.removeModerator(id, 'mod');
      snap = await groups.doc(id).get();
      expect(snap.data()!['roles']['mod'], isNull);
    });

    test('only owner or moderator may update basics', () async {
      final ownerService = GroupsService(firestore: firestore, auth: _FakeAuth('owner'));
      final id = await ownerService.createGroup(name: 'old');
      await ownerService.addModerator(id, 'mod');
      await groups.doc(id).update({
        'memberIds': FieldValue.arrayUnion(['mod', 'user'])
      });

      final modService = GroupsService(firestore: firestore, auth: _FakeAuth('mod'));
      await modService.updateGroup(id, name: 'new');
      var snap = await groups.doc(id).get();
      expect(snap.data()!['name'], 'new');

      final userService = GroupsService(firestore: firestore, auth: _FakeAuth('user'));
      expect(userService.updateGroup(id, name: 'fail'), throwsException);
    });
  });
}
