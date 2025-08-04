import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:fouta_app/utils/video_controller_extensions.dart';

/// Screen used to create and post a story.
///
/// Displays a preview of the media captured from the camera or gallery and
/// allows the user to submit it.
class StoryCreationScreen extends StatefulWidget {
  /// Path to the media chosen or captured by the user.
  final String initialMediaPath;

  /// Whether the media is a video.
  final bool isVideo;

  const StoryCreationScreen({
    Key? key,
    required this.initialMediaPath,
    required this.isVideo,
  }) : super(key: key ?? ValueKey(initialMediaPath));

  @override
  State<StoryCreationScreen> createState() => _StoryCreationScreenState();
}

class _StoryCreationScreenState extends State<StoryCreationScreen> {
  Player? _player;
  VideoController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    _player = Player();
    try {
      await _player!.open(Media(widget.initialMediaPath));
      await _player!.play();
      if (!mounted) return;
      setState(() {
        _controller = VideoController(_player!);
      });
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget preview;
    if (widget.isVideo) {
      preview = (_controller != null)
          ? Video(
              key: ValueKey(widget.initialMediaPath),
              controller: _controller!,
              fit: BoxFit.contain,
            )
          : const CircularProgressIndicator(color: Colors.white);
    } else {
      preview = Image.file(
        File(widget.initialMediaPath),
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

