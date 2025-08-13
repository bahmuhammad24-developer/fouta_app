import 'package:flutter/material.dart';

class StoryInlineReplyChip extends StatelessWidget {
  const StoryInlineReplyChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ActionChip(
          label: const Text('Reply'),
          onPressed: onTap,
        ),
      ),
    );
  }
}
