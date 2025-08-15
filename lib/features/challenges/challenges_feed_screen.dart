// lib/features/challenges/challenges_feed_screen.dart

import 'package:flutter/material.dart';
import 'package:fouta_app/widgets/fouta_card.dart';

/// Simple data model for a challenge.
class Challenge {
  final String title;
  final String description;

  const Challenge({required this.title, required this.description});
}

/// Displays a list of [ChallengeCard]s using mock data.
class ChallengesFeedScreen extends StatelessWidget {
  static const route = '/challenges';

  const ChallengesFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const mockChallenges = [
      Challenge(
        title: 'Community Garden',
        description: 'Start a shared garden in the neighborhood.',
      ),
      Challenge(
        title: 'Beach Cleanup',
        description: 'Organize a cleanup of the local beach area.',
      ),
      Challenge(
        title: 'School Supplies Drive',
        description: 'Collect supplies for the new school year.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Challenges')),
      body: ListView.builder(
        itemCount: mockChallenges.length,
        itemBuilder: (context, index) {
          final challenge = mockChallenges[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ChallengeCard(challenge: challenge),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: null, // Disabled until creation flow is available.
        tooltip: 'New Challenge',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Tier-3 composite card for displaying a [Challenge].
class ChallengeCard extends StatelessWidget {
  final Challenge challenge;

  const ChallengeCard({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    return FoutaCard(
      child: ListTile(
        title: Text(challenge.title),
        subtitle: Text(challenge.description),
      ),
    );
  }
}
