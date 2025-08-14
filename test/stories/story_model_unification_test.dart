import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/models/media_item.dart';
import 'package:fouta_app/models/story.dart';

void main() {
  test('Story construction includes unified fields', () {
    final item = StoryItem(
      id: 'slide1',
      media: const MediaItem(id: 'm1', type: MediaType.image, url: 'u1'),
    );
    final story = Story(
      id: 's1',
      authorId: 'a1',
      userName: 'Alice',
      userImageUrl: 'img.png',
      postedAt: DateTime(2024, 1, 1),
      expiresAt: DateTime(2024, 1, 2),
      items: [item],
    );
    expect(story.userName, 'Alice');
    expect(story.items.first.id, 'slide1');
  });

  test('viewedBy and hasUnviewedBy work', () {
    final item = StoryItem(
      media: const MediaItem(id: 'm2', type: MediaType.image, url: 'u2'),
      viewers: const ['u1'],
    );
    expect(item.viewedBy('u1'), isTrue);
    final story = Story(
      id: 's2',
      authorId: 'a2',
      postedAt: DateTime(2024, 1, 1),
      expiresAt: DateTime(2024, 1, 2),
      items: [item],
    );
    expect(story.hasUnviewedBy('u1'), isFalse);
    expect(story.hasUnviewedBy('u2'), isTrue);
  });

  test('displayDuration uses overrides and fallbacks', () {
    const media = MediaItem(
      id: 'm3',
      type: MediaType.image,
      url: 'u3',
      duration: Duration(seconds: 10),
    );
    final overrideItem = StoryItem(
      media: media,
      overrideDuration: const Duration(seconds: 3),
    );
    expect(overrideItem.displayDuration, const Duration(seconds: 3));

    final mediaDurationItem = StoryItem(media: media);
    expect(mediaDurationItem.displayDuration, const Duration(seconds: 10));

    final defaultItem = StoryItem(
      media: const MediaItem(id: 'm4', type: MediaType.image, url: 'u4'),
    );
    expect(defaultItem.displayDuration, const Duration(seconds: 6));
  });
}
