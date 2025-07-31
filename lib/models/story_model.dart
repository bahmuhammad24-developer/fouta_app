// lib/models/story_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class StorySlide {
  final String id;
  final String url;
  final String mediaType;
  final Timestamp timestamp;
  final List<dynamic> viewers;

  StorySlide({
    required this.id,
    required this.url,
    required this.mediaType,
    required this.timestamp,
    required this.viewers,
  });
}

class Story {
  final String userId;
  final String userName;
  final String userImageUrl;
  final List<StorySlide> slides;

  Story({
    required this.userId,
    required this.userName,
    required this.userImageUrl,
    required this.slides,
  });
}