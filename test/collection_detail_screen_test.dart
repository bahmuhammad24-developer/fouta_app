import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/screens/collections/collection_detail_screen.dart';
import 'package:fouta_app/services/collections_service.dart';

void main() {
  testWidgets('save/remove from collection updates list', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final service = CollectionsService(firestore: firestore);
    const uid = 'u1';
    final collectionId = await service.createCollection(uid, 'Favs');
    await service.addToCollection(uid, collectionId, 'post1');

    await tester.pumpWidget(MaterialApp(
      home: CollectionDetailScreen(
        collectionId: collectionId,
        collectionName: 'Favs',
        overrideUid: uid,
      ),
    ));
    await tester.pump();
    expect(find.text('Post post1'), findsOneWidget);

    await service.removeFromCollection(uid, collectionId, 'post1');
    await tester.pump();
    expect(find.text('Post post1'), findsNothing);
  });
}
