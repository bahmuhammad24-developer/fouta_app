// lib/widgets/triggers/story_inline_reply_chip.dart
import 'package:flutter/material.dart';

/// Non-modal reply affordance you can overlay on a story viewer.
/// Hook onReply to open your DM composer with context.
class StoryInlineReplyChip extends StatelessWidget {
  final VoidCallback onReply;

  const StoryInlineReplyChip({
    super.key,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    // Use Positioned in parent or put this at the bottom of your story controls.
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ElevatedButton.icon(
        onPressed: onReply,
        icon: const Icon(Icons.reply),
        label: const Text('Reply'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }
}
