import 'media_item.dart';

/// A collection of story items posted by a single author.
class Story {
  final String id;
  final String authorId;
  final DateTime postedAt;
  final DateTime expiresAt;
  final List<StoryItem> items;
  final bool seen;

  const Story({
    required this.id,
    required this.authorId,
    required this.postedAt,
    required this.expiresAt,
    this.items = const [],
    this.seen = false,
  });
}

/// A single item within a story.
class StoryItem {
  final MediaItem media;
  final Duration? overrideDuration;
  final String? caption;

  const StoryItem({
    required this.media,
    this.overrideDuration,
    this.caption,
  });

  /// The duration the item should be displayed.
  Duration get displayDuration =>
      overrideDuration ?? media.duration ?? const Duration(seconds: 6);
}
