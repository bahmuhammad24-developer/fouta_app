import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/screens/profile_screen.dart';
import 'package:fouta_app/utils/firestore_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  testWidgets('pinned post renders', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection(FirestorePaths.users()).doc('u1').set({
      'displayName': 'A',
      'pinnedPostId': 'p1',
    });
    await firestore.collection(FirestorePaths.posts()).doc('p1').set({
      'authorId': 'u1',
      'timestamp': Timestamp.now(),
    });

    await tester.pumpWidget(MaterialApp(
        home: ProfileScreen(userId: 'u1', firestore: firestore)));
    await tester.pump();
    expect(find.text('Pinned Post'), findsOneWidget);
  });

  testWidgets('creator dashboard shows numbers', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection(FirestorePaths.users()).doc('u2').set({
      'displayName': 'B',
      'isCreator': true,
      'followers': ['f1', 'f2'],
    });
    await firestore.collection(FirestorePaths.posts()).add({
      'authorId': 'u2',
      'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      'likeIds': ['l1', 'l2'],
    });

    await tester.pumpWidget(MaterialApp(
        home: ProfileScreen(userId: 'u2', firestore: firestore)));
    await tester.pumpAndSettle();
    expect(find.text('Followers'), findsWidgets);
    expect(find.text('7-day posts'), findsOneWidget);
    expect(find.text('7-day engagement'), findsOneWidget);
    expect(find.text('2'), findsWidgets); // follower count and engagement
  });
}
