import 'media_item.dart';

/// Alias types aligning with story terminology.
typedef UserStories = Story;
typedef StorySlide = StoryItem;

/// A collection of story items posted by a single author.
class Story {
  final String id;
  final String authorId;
  final String? userName;
  final String? userImageUrl;
  final DateTime postedAt;
  final DateTime expiresAt;
  final List<StoryItem> items;
  final bool seen;
  final List<String> viewedBy;

  const Story({
    required this.id,
    required this.authorId,
    this.userName,
    this.userImageUrl,
    required this.postedAt,
    required this.expiresAt,
    this.items = const [],
    this.seen = false,
    this.viewedBy = const [],
  });
}

/// A single item within a story.
class StoryItem {
  final String id;
  final MediaItem media;
  final Duration? overrideDuration;
  final String? caption;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final List<String> viewers;

  const StoryItem({
    String? id,
    required this.media,
    this.overrideDuration,
    this.caption,
    this.createdAt,
    this.expiresAt,
    this.viewers = const [],
  }) : id = id ?? media.id;

  /// The duration the item should be displayed.
  Duration get displayDuration =>
      overrideDuration ?? media.duration ?? const Duration(seconds: 6);
}

extension StorySlideX on StorySlide {
  bool viewedBy(String uid) => viewers.contains(uid);
}

extension UserStoriesX on UserStories {
  bool hasUnviewedBy(String uid) =>
      items.any((s) => !s.viewedBy(uid));
}
