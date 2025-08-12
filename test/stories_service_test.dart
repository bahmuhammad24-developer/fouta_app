import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/models/media_item.dart';
import 'package:fouta_app/models/story.dart';
import 'package:fouta_app/services/stories_service.dart';

class _MemoryViewsStore implements StoryViewsStore {
  final Map<String, Map<String, Map<String, dynamic>>> data = {};

  @override
  Future<void> saveView(String storyId, StoryItem item) async {
    data.putIfAbsent(storyId, () => {});
    data[storyId]![item.media.url] = {'seenAt': DateTime.now()};
  }
}

void main() {
  test('markItemSeen caches and persists', () async {
    final store = _MemoryViewsStore();
    final service = StoriesService(store: store);
    final item = StoryItem(
      media: const MediaItem(id: '1', type: MediaType.image, url: 'url1'),
    );

    await service.markItemSeen('story1', item);
    expect(service.isItemSeen(item), true);
    expect(store.data['story1']!.containsKey('url1'), true);
  });
}
