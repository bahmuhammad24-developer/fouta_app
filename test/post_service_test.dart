import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/services/post_service.dart';
import 'package:fouta_app/utils/firestore_paths.dart';
import 'package:firebase_auth/firebase_auth.dart';

class _FakeUser implements User {
  _FakeUser(this.uid);
  @override
  final String uid;
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuth implements FirebaseAuth {
  _FakeAuth(this._user);
  final User _user;
  @override
  User? get currentUser => _user;
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('repost sets origin fields', () async {
    final firestore = FakeFirebaseFirestore();
    final auth = _FakeAuth(_FakeUser('u1'));
    await firestore.collection(FirestorePaths.users()).doc('u1').set({'displayName': 'Alice'});
    await firestore.collection(FirestorePaths.posts()).doc('p1').set({
      'authorId': 'a1',
      'authorDisplayName': 'Ann',
      'content': 'hi',
      'mediaUrl': '',
      'mediaType': 'text',
    });
    final service = PostService(firestore: firestore, auth: auth);
    await service.repost('p1');
    final posts = await firestore.collection(FirestorePaths.posts()).get();
    expect(posts.docs.length, 2);
    final created = posts.docs.firstWhere((d) => d.id != 'p1');
    expect(created['type'], 'repost');
    expect(created['originPostId'], 'p1');
    expect(created['originAuthorId'], 'a1');
  });

  test('quotePost stores quote text', () async {
    final firestore = FakeFirebaseFirestore();
    final auth = _FakeAuth(_FakeUser('u1'));
    await firestore.collection(FirestorePaths.users()).doc('u1').set({'displayName': 'Alice'});
    await firestore.collection(FirestorePaths.posts()).doc('p1').set({
      'authorId': 'a1',
      'authorDisplayName': 'Ann',
      'content': 'hi',
      'mediaUrl': '',
      'mediaType': 'text',
    });
    final service = PostService(firestore: firestore, auth: auth);
    await service.quotePost('p1', 'nice');
    final posts = await firestore.collection(FirestorePaths.posts()).get();
    expect(posts.docs.length, 2);
    final created = posts.docs.firstWhere((d) => d.id != 'p1');
    expect(created['type'], 'quote');
    expect(created['quoteText'], 'nice');
    expect(created['originPostId'], 'p1');
  });
}
