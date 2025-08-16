import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fouta_app/features/marketplace/seller_service.dart';

void main() {
  test('createSellerProfile stores document and isSeller returns true', () async {
    final firestore = FakeFirebaseFirestore();
    final service = SellerService(firestore: firestore);
    await service.createSellerProfile(
      userId: 'u1',
      displayName: 'Alice',
      bio: 'Hello',
    );
    final isSeller = await service.isSeller('u1');
    expect(isSeller, isTrue);
    final doc = await firestore.collection('sellers').doc('u1').get();
    expect(doc.data()?['displayName'], 'Alice');
  });
}
