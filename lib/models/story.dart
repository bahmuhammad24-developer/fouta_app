import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/json_safety.dart';
import 'media_item.dart';

/// Alias types aligning with story terminology.
typedef UserStories = Story;
typedef StorySlide = StoryItem;

DateTime? _dateTime(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) return DateTime.tryParse(v);
  return null;
}

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

  factory Story.fromMap(String id, Map<String, dynamic> data) {
    final items =
        asListOf<Map<String, dynamic>>(data['items']).map(StoryItem.fromMap).
            whereType<StoryItem>().toList();
    return Story(
      id: id,
      authorId: data['authorId']?.toString() ?? '',
      postedAt: _dateTime(data['postedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      expiresAt: _dateTime(data['expiresAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      items: items,
      seen: data['seen'] == true,
      viewedBy: asStringList(data['viewedBy']),
    );
  }
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

  static StoryItem? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final media = MediaItem.fromMap(map['media'] as Map<String, dynamic>?) ??
        MediaItem.fromMap(map);
    if (media == null) return null;

    Duration? override;
    final od = map['displayDurationMs'];
    if (od is int) {
      override = Duration(milliseconds: od);
    } else if (od is String) {
      final ms = int.tryParse(od);
      if (ms != null) override = Duration(milliseconds: ms);
    }

    return StoryItem(
      media: media,
      overrideDuration: override,
      caption: map['caption']?.toString(),
      createdAt: _dateTime(map['createdAt']),
      expiresAt: _dateTime(map['expiresAt']),
      viewers: asStringList(map['viewers']),
    );
  }

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
