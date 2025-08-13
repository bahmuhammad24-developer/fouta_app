import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/features/profile/profile_service.dart';
import 'package:fouta_app/utils/firestore_paths.dart';

void main() {
  test('sanitizeLinks filters non http(s)', () async {
    final firestore = FakeFirebaseFirestore();
    final service = ProfileService(firestore: firestore);
    await service.updateProfile('u1', links: [
      'https://good.com',
      'ftp://bad.com',
      'http://also-good.com'
    ]);
    final doc = await firestore.collection(FirestorePaths.users()).doc('u1').get();
    expect(doc.data()!['links'], ['https://good.com', 'http://also-good.com']);
  });

  test('pin and unpin post', () async {
    final firestore = FakeFirebaseFirestore();
    final service = ProfileService(firestore: firestore);
    await service.pinPost('u1', 'p1');
    var doc = await firestore.collection(FirestorePaths.users()).doc('u1').get();
    expect(doc.data()!['pinnedPostId'], 'p1');
    await service.unpinPost('u1');
    doc = await firestore.collection(FirestorePaths.users()).doc('u1').get();
    expect(doc.data()!.containsKey('pinnedPostId'), isFalse);
  });
}
