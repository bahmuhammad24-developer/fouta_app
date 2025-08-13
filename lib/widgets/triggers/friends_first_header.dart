import 'package:flutter/material.dart';

class FriendsFirstHeader extends StatelessWidget {
  const FriendsFirstHeader({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: const Text('New from friends'),
        onTap: onTap,
      ),
    );
  }
}
