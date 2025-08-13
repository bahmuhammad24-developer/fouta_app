// lib/widgets/triggers/friends_first_header.dart
import 'package:flutter/material.dart';

class FriendsFirstHeader extends StatelessWidget {
  final int newPostsCount;
  final VoidCallback onSeeFriends;

  const FriendsFirstHeader({
    super.key,
    required this.newPostsCount,
    required this.onSeeFriends,
  });

  @override
  Widget build(BuildContext context) {
    if (newPostsCount <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Card(
        elevation: 0.5,
        child: ListTile(
          leading: const Icon(Icons.group),
          title: Text('New from friends'),
          subtitle: Text('$newPostsCount recent post${newPostsCount == 1 ? '' : 's'}'),
          trailing: TextButton(
            onPressed: onSeeFriends,
            child: const Text('See'),
          ),
        ),
      ),
    );
  }
}
