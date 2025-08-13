import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fouta_app/main.dart';
import 'package:fouta_app/screens/notifications_inbox_screen.dart';

void main() {
  testWidgets('inbox renders items and marks read on tap', (tester) async {
    final firestore = FakeFirebaseFirestore();
    const uid = 'user1';
    await firestore
        .collection('artifacts/$APP_ID/public/data/notifications')
        .doc(uid)
        .collection('items')
        .doc('n1')
        .set({
          'type': 'likes',
          'actorId': 'actor',
          'postId': 'post1',
          'createdAt': Timestamp.now(),
          'read': false,
        });

    await tester.pumpWidget(MaterialApp(
      home: NotificationsInboxScreen(firestore: firestore, uid: uid),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    final doc = await firestore
        .collection('artifacts/$APP_ID/public/data/notifications')
        .doc(uid)
        .collection('items')
        .doc('n1')
        .get();
    expect(doc.data()?['read'], true);
  });
}
