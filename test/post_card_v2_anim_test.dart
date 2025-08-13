import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/widgets/post_card_widget.dart';

void main() {
  testWidgets('like and bookmark toggles without exception', (tester) async {
    final data = {
      'content': 'Hello',
      'likes': <String>[],
      'bookmarks': <String>[],
      'shares': 0,
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

    final likeFinder = find.byIcon(Icons.favorite_border);
    final bookmarkFinder = find.byIcon(Icons.bookmark_border);

    expect(likeFinder, findsOneWidget);
    expect(bookmarkFinder, findsOneWidget);

    await tester.tap(likeFinder);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    await tester.tap(bookmarkFinder);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.bookmark), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}

