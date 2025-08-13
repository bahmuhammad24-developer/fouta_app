import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../stories_service.dart';
import '../../../features/creation/editor/overlays/editor_canvas.dart';

/// Screen for composing a story with overlay editing.
class CreateStoryScreen extends StatefulWidget {
  final String? initialImagePath;
  final String? initialVideoPath;

  const CreateStoryScreen({
    super.key,
    this.initialImagePath,
    this.initialVideoPath,
  });

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _canvasKey = GlobalKey<EditorCanvasState>();
  bool _uploading = false;

  String get _path => widget.initialVideoPath ?? widget.initialImagePath ?? '';
  String get _type => widget.initialVideoPath != null ? 'video' : 'image';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Story')),
      body: EditorCanvas(
        key: _canvasKey,
        mediaPath: _path,
        mediaType: _type,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploading ? null : _share,
        child: _uploading
            ? const CircularProgressIndicator()
            : const Icon(Icons.send),
      ),
    );
  }

  Future<void> _share() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please log in')));
      return;
    }
    setState(() => _uploading = true);
    try {
      final file = File(_path);
      final ext = _type == 'video' ? 'mp4' : 'jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('stories/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.$ext');
      final metadata = SettableMetadata(
          contentType: _type == 'video' ? 'video/mp4' : 'image/jpeg');
      await ref.putFile(file, metadata);
      final url = await ref.getDownloadURL();

      final overlays = _canvasKey.currentState?.getSerializedOverlays() ?? [];
      await StoriesService().createStory(
        userId: user.uid,
        mediaUrl: url,
        mediaType: _type,
        overlays: overlays,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to share story')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}

