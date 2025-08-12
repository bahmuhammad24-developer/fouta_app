import 'media_item.dart';

/// Basic post model exposing media attachments.
class Post {
  Post({
    required this.id,
    required this.content,
    required this.attachments,
    required this.bookmarks,
  });

  final String id;
  final String content;
  final List<MediaItem> attachments;
  final List<String> bookmarks;

  factory Post.fromMap(String id, Map<String, dynamic> data) {
    final attachmentList = (data['attachments'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(MediaItem.fromMap)
        .whereType<MediaItem>()
        .toList();
    return Post(
      id: id,
      content: data['content'] as String? ?? '',
      attachments: attachmentList,
      bookmarks:
          List<String>.from(data['bookmarks'] as List<dynamic>? ?? const []),
    );
  }
}
