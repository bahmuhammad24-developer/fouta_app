
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/models/story.dart';

void main() {
  test('Story and StoryItem from Firestore map', () {
    final itemMap1 = {
      'media': {
        'id': 'm1',
        'type': 'image',
        'url': 'https://example.com/1.jpg',
      },
      'viewers': ['u1'],
    };
    final itemMap2 = {
      'media': {
        'id': 'm2',
        'type': 'image',
        'url': 'https://example.com/2.jpg',
      },
      'viewers': <String>[],
    };
    final storyMap = {
      'authorId': 'author',
      'postedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      'expiresAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
      'items': [itemMap1, itemMap2],
      'viewedBy': ['u1'],
    };

    final story = Story.fromMap('story1', storyMap);
    expect(story.viewedBy.contains('u1'), isTrue);
    expect(story.items.first.viewedBy('u1'), isTrue);
    expect(story.items.first.viewedBy('u2'), isFalse);
    expect(story.hasUnviewedBy('u1'), isTrue);
    expect(story.hasUnviewedBy('u2'), isTrue);
  });

  test('displayDuration override and default', () {
    final withOverride = StoryItem.fromMap({
      'media': {
        'id': 'm3',
        'type': 'image',
        'url': 'https://example.com/3.jpg',
      },
      'displayDurationMs': 3000,
    })!;
    expect(withOverride.displayDuration, const Duration(seconds: 3));

    final withMediaDur = StoryItem.fromMap({
      'media': {
        'id': 'm4',
        'type': 'video',
        'url': 'https://example.com/4.mp4',
        'duration': 4000,
      },
    })!;
    expect(withMediaDur.displayDuration, const Duration(milliseconds: 4000));

    final defaultItem = StoryItem.fromMap({
      'media': {
        'id': 'm5',
        'type': 'image',
        'url': 'https://example.com/5.jpg',
      },
    })!;

    expect(defaultItem.displayDuration, const Duration(seconds: 6));
  });
}
