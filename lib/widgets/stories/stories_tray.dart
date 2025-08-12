import 'package:flutter/material.dart';

import '../../models/story.dart';

const double kStoryOuterSize = 68;
const double kStoryRingWidth = 3;
const double kStoryAvatarSize = kStoryOuterSize - (kStoryRingWidth * 2);
const double kBadgeSize = 18;

class StoriesTray extends StatelessWidget {
  const StoriesTray({
    super.key,
    this.stories = const [],
    required this.currentUserId,
    this.onAdd,
    this.onStoryTap,
  });

  final List<Story> stories;
  final String currentUserId;
  final VoidCallback? onAdd;
  final void Function(Story story)? onStoryTap;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface,
        );

    final current = stories.firstWhere(
      (s) => s.authorId == currentUserId,
      orElse: () => Story(
        id: currentUserId,
        authorId: currentUserId,
        postedAt: DateTime.now(),
        expiresAt: DateTime.now(),
      ),
    );
    final others = stories.where((s) => s.authorId != currentUserId).toList();

    return SizedBox(
      height: 92,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          if (index == 0) {
            final hasActive = current.items.isNotEmpty;
            final slide = hasActive ? current.items.first : null;
            final imageUrl = slide?.media.thumbUrl ?? slide?.media.url;
            return _storyBubble(
              context: context,
              imageUrl: imageUrl,
              label: 'Your Story',
              isUnviewed: hasActive,
              showAddBadge: !hasActive && onAdd != null,
            );
          }
          final story = others[index - 1];
          final slide = story.items.isNotEmpty ? story.items.first : null;
          final imageUrl = slide?.media.thumbUrl ?? slide?.media.url;
          return GestureDetector(
            onTap: () => onStoryTap?.call(story),
            child: _storyBubble(
              context: context,
              imageUrl: imageUrl,
              label: story.authorId,
              isUnviewed: story.hasUnviewedBy(currentUserId),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: 1 + others.length,
      ),
    );
  }
}

Widget _storyBubble({
  required BuildContext context,
  required String? imageUrl,
  required String label,
  required bool isUnviewed,
  bool showAddBadge = false,
}) {
  final scheme = Theme.of(context).colorScheme;

  final BoxDecoration ringDecoration = isUnviewed
      ? const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF138A5A),
              Color(0xFFD4AF37),
            ],
          ),
        )
      : BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.outlineVariant.withOpacity(0.35),
        );

  final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface,
      );

  return SizedBox(
    width: kStoryOuterSize,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              width: kStoryOuterSize,
              height: kStoryOuterSize,
              decoration: ringDecoration,
              padding: const EdgeInsets.all(kStoryRingWidth),
              child: ClipOval(
                child: (imageUrl == null || imageUrl.isEmpty)
                    ? Container(color: scheme.surfaceVariant)
                    : Image.network(imageUrl, fit: BoxFit.cover),
              ),
            ),
            if (showAddBadge)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: kBadgeSize,
                  height: kBadgeSize,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.add, size: 14, color: scheme.onPrimary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(label,
            maxLines: 1, overflow: TextOverflow.ellipsis, style: labelStyle),
      ],
    ),
  );
}
