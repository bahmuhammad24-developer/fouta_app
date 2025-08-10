import 'media_item.dart';

/// Basic post model exposing media attachments.
class Post {
  Post({required this.id, required this.content, required this.attachments});

  final String id;
  final String content;
  final List<MediaItem> attachments;

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
    );
  }
}
