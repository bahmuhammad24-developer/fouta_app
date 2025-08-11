import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:fouta_app/utils/video_controller_extensions.dart';
import 'package:fouta_app/utils/snackbar.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../data/story_repository.dart';
import '../../../models/story.dart';
import '../../../models/media_item.dart';

/// Composer for creating and publishing a story slide.
class CreateStoryScreen extends StatefulWidget {
  final String? initialImagePath;
  final String? initialVideoPath;
  final String? initialCaption;

  const CreateStoryScreen({
    super.key,
    this.initialImagePath,
    this.initialVideoPath,
    this.initialCaption,
  });

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  Player? _player;
  VideoController? _controller;
  bool _isUploading = false;
  late final TextEditingController _captionController;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.initialCaption ?? '');
    if (widget.initialVideoPath != null) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    _player = Player();
    try {
      // `media_kit` interprets bare paths as remote URLs, yielding a black
      // preview. Prefix with `file://` so it knows the source is local.
      final uri = Uri.file(widget.initialVideoPath!).toString();
      await _player!.open(Media(uri));
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
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget preview;
    final isVideo = widget.initialVideoPath != null;
    if (isVideo) {
      preview = (_controller != null)
          ? Video(
              key: ValueKey(widget.initialVideoPath),
              controller: _controller!,
              fit: BoxFit.contain,
            )
          : CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary);
    } else {
      preview = Image.file(
        File(widget.initialImagePath ?? ''),
        fit: BoxFit.contain,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Story'),
      ),
      backgroundColor: Theme.of(context).colorScheme.onSurface,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _isUploading
                  ? CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary)
                  : preview,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _captionController,
              decoration: const InputDecoration(hintText: 'Say something...'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _uploadStory,
        child: const Icon(Icons.send),
      ),
    );
  }

  Future<void> _uploadStory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        AppSnackBar.show(context, 'Please log in to post stories',
            isError: true);
      }
      return;
    }

    setState(() => _isUploading = true);
    try {
      final String path =
          widget.initialVideoPath ?? widget.initialImagePath ?? '';
      final mediaFile = File(path);
      final bool isVideo = widget.initialVideoPath != null;
      final repo = StoryRepository();
      final item = await repo.publishSlide(
        user.uid,
        mediaFile,
        isVideo ? MediaType.video : MediaType.image,
        caption: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
      );

      if (mounted) Navigator.pop(context, item);
    } catch (e) {
      debugPrint('Error uploading story: $e');
      if (mounted) {
        AppSnackBar.show(context, 'Failed to upload story', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}

