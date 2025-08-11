import 'package:flutter/material.dart';

import 'create_story_screen.dart';

/// Simple wrapper around [CreateStoryScreen] so that existing
/// capture flow can push a review screen without disposing the
/// camera prematurely.
class StoryReviewScreen extends StatelessWidget {
  final String? imagePath;
  final String? videoPath;
  final String? caption;

  const StoryReviewScreen({super.key, this.imagePath, this.videoPath, this.caption});

  @override
  Widget build(BuildContext context) {
    return CreateStoryScreen(
      initialImagePath: imagePath,
      initialVideoPath: videoPath,
      initialCaption: caption,
    );
  }
}
