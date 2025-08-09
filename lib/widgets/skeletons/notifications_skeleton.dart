import 'package:flutter/material.dart';

class NotificationsSkeleton extends StatelessWidget {
  const NotificationsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 5,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, __) => ListTile(
        leading: CircleAvatar(backgroundColor: Colors.grey.shade300),
        title: Container(
          height: 12,
          color: Colors.grey.shade300,
        ),
        subtitle: Container(
          height: 12,
          margin: const EdgeInsets.only(top: 4),
          color: Colors.grey.shade200,
        ),
      ),
    );
  }
}
