import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fouta_app/main.dart';
import 'package:fouta_app/screens/post_detail_screen.dart';
import 'package:fouta_app/widgets/post_card_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const postId = 'post1';
  final postData = {
    'authorId': 'user1',
    'mediaUrl': 'https://example.com/image.jpg',
    'mediaType': 'image',
    'content': 'hello',
    'likes': <String>[],
    'bookmarks': <String>[],
    'timestamp': Timestamp.now(),
  };

  testWidgets('Hero tag present on card and detail', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await firestore
        .collection('artifacts/$APP_ID/public/data/posts')
        .doc(postId)
        .set(postData);

    // Build post card
    await tester.pumpWidget(MaterialApp(
      home: PostCardWidget(
        post: postData,
        postId: postId,
        currentUser: null,
        appId: APP_ID,
        onMessage: (_) {},
        isDataSaverOn: false,
        isOnMobileData: false,
      ),
    ));
    final cardHero = tester.widget<Hero>(find.byType(Hero));
    expect(cardHero.tag, '${postId}-media');

    // Build detail screen
    await tester.pumpWidget(MaterialApp(
      home: PostDetailScreen(postId: postId, firestore: firestore),
    ));
    await tester.pump();
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (w) => w is Hero && w.tag == '${postId}-media',
      ),
      findsOneWidget,
    );
  });
}
