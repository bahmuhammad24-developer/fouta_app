import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fouta_app/features/challenges/challenge_card.dart';
import 'package:fouta_app/features/challenges/mock_challenges.dart';

void main() {
  testWidgets('ChallengeCard shows text and buttons', (tester) async {
    final challenge = mockChallenges.first;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ChallengeCard(challenge: challenge)),
    ));

    expect(find.text(challenge.title), findsOneWidget);
    expect(find.text('Upvote'), findsOneWidget);
    expect(find.text('Downvote'), findsOneWidget);
    for (final tag in challenge.tags) {
      expect(find.text(tag), findsOneWidget);
    }
  });
}
