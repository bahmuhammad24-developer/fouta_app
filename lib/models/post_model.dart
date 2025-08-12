import 'media_item.dart';
import '../utils/json_safety.dart';

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
    final attachmentList = asListOf<Map<String, dynamic>>(data['attachments'])
        .map(MediaItem.fromMap)
        .whereType<MediaItem>()
        .toList();
    return Post(
      id: id,
      content: data['content']?.toString() ?? '',
      attachments: attachmentList,
      bookmarks: asStringList(data['bookmarks']),
    );
  }
}
