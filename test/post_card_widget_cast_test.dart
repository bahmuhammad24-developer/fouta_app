import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/widgets/post_card_widget.dart';

void main() {
  testWidgets('PostCardWidget handles list fields safely', (tester) async {
    final data = {
      'content': 'Hello',
      'likes': ['u1', 'u2'],
      'bookmarks': [],
      'shares': 1,
      'authorId': 'a1',
      'timestamp': Timestamp.now(),
      'media': [],
    };

    await tester.pumpWidget(
      MaterialApp(
        home: PostCardWidget(
          post: data,
          postId: 'p1',
          currentUser: null,
          appId: 'test',
          onMessage: (_) {},
          isDataSaverOn: true,
          isOnMobileData: false,
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
  });
}
