import 'dart:io';

import 'package:flutter/material.dart';

/// Screen used to create and post a story.
///
/// Displays a preview of the media captured from the camera or gallery and
/// allows the user to submit it. Video preview is not implemented yet but the
/// screen still accepts video files so the flow can be wired up end‑to‑end.
class StoryCreationScreen extends StatelessWidget {
  /// Path to the media chosen or captured by the user.
  final String initialMediaPath;

  /// Whether the media is a video. If `true`, a simple placeholder is shown
  /// instead of an image preview.
  final bool isVideo;

  const StoryCreationScreen({
    super.key,
    required this.initialMediaPath,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    Widget preview;
    if (isVideo) {
      preview = Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const Text(
          'Video preview not implemented',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      preview = Image.file(
        File(initialMediaPath),
        fit: BoxFit.contain,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Story'),
      ),
      backgroundColor: Colors.black,
      body: Center(child: preview),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // In a full implementation this would upload the story and then
          // navigate away. For now it simply pops back to the previous screen.
          Navigator.pop(context);
        },
        child: const Icon(Icons.send),
      ),
    );
  }
}

