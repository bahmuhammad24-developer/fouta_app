import 'package:flutter/material.dart';

import 'package:fouta_app/widgets/fouta_button.dart';

import 'mock_challenges.dart';

/// Tier-3 widget that displays basic information about a [Challenge].
///
/// It shows the title, a short description snippet, tags, author placeholder,
/// timestamp and simple voting actions using design system components.
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({super.key, required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              challenge.title,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              challenge.description,
              style: theme.textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children:
                  challenge.tags.map((t) => Chip(label: Text(t))).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('by ${challenge.author}',
                    style: theme.textTheme.bodySmall),
                Text(_formatTimestamp(challenge.createdAt),
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FoutaButton(
                  label: 'Upvote',
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                Text('${challenge.score}',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(width: 8),
                FoutaButton(
                  label: 'Downvote',
                  onPressed: () {},
                  primary: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
