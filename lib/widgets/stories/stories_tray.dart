import 'package:flutter/material.dart';

import '../../models/story.dart';

/// Horizontal list of user stories with unread/seen indicators.
class StoriesTray extends StatelessWidget {
  const StoriesTray({super.key, this.stories = const [], required this.currentUserId, this.onAdd, this.onStoryTap});
  final List<Story> stories;
  final String currentUserId;
  final VoidCallback? onAdd;
  final ValueChanged<Story>? onStoryTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          final isMe = story.authorId == currentUserId;
          final hasSeen = story.seen;
          final label =
              '${story.authorId} story, ${hasSeen ? 'seen' : 'unread'}, posted ${_relativeTime(story.postedAt)}';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Semantics(
              button: true,
              label: label,
              child: InkWell(
                onTap: () => onStoryTap?.call(story),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hasSeen ? cs.outlineVariant : cs.primary,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          story.items.isNotEmpty
                              ? story.items.first.media.thumbUrl
                              : '',
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, __) =>
                              Container(color: cs.surfaceVariant),
                        ),
                      ),
                    ),
                    if (isMe)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: onAdd,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add,
                              size: 16,
                              color: cs.onPrimary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _relativeTime(DateTime postedAt) {
    final diff = DateTime.now().difference(postedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
