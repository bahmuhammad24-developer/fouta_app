import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/widgets/post_card_widget.dart';

void main() {
  testWidgets('text scale clamps to prevent overflow', (tester) async {
    final post = {
      'authorId': 'a',
      'authorDisplayName': 'Author',
      'content': 'lorem ipsum ' * 20,
      'media': [],
      'type': 'original',
    };

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaleFactor: 3.0),
        child: MaterialApp(
          home: PostCardWidget(
            post: post,
            postId: '1',
            currentUser: null,
            appId: 'app',
            onMessage: (_) {},
            isDataSaverOn: false,
            isOnMobileData: false,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
