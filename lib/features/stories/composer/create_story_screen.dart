import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../stories_service.dart';
import '../../../features/creation/editor/overlays/editor_canvas.dart';
import '../../../features/creation/editor/overlays/overlay_models.dart';
import 'package:fouta_app/widgets/fouta_button.dart';

/// Screen for composing a story with overlay editing.
class CreateStoryScreen extends StatefulWidget {
  final String? initialImagePath;
  final String? initialVideoPath;
  final String? initialImageUrl;
  final String? initialVideoUrl;
  final List<OverlayModel>? initialOverlays;

  const CreateStoryScreen({
    super.key,
    this.initialImagePath,
    this.initialVideoPath,
    this.initialImageUrl,
    this.initialVideoUrl,
    this.initialOverlays,
  });

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _canvasKey = GlobalKey<EditorCanvasState>();
  bool _uploading = false;

  String get _path =>
      widget.initialVideoPath ??
      widget.initialImagePath ??
      widget.initialVideoUrl ??
      widget.initialImageUrl ??
      '';
  String get _type =>
      (widget.initialVideoPath != null || widget.initialVideoUrl != null)
          ? 'video'
          : 'image';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Story')),
      body: EditorCanvas(
        key: _canvasKey,
        mediaPath: _path,
        mediaType: _type,
        initialOverlays: widget.initialOverlays,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FoutaButton(
              label: _uploading ? 'Sharing...' : 'Share Story',
              onPressed: _uploading ? () {} : _share,
              primary: true,
              expanded: true,
            ),
            const SizedBox(height: 8),
            FoutaButton(
              label: 'Cancel',
              onPressed: _uploading ? () {} : () => Navigator.pop(context),
              primary: false,
              expanded: true,
            ),
          ],
        ),
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
      final ext = _type == 'video' ? 'mp4' : 'jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('stories/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.$ext');
      final metadata = SettableMetadata(
          contentType: _type == 'video' ? 'video/mp4' : 'image/jpeg');
      if (_path.startsWith('http')) {
        final resp = await http.get(Uri.parse(_path));
        await ref.putData(resp.bodyBytes, metadata);
      } else {
        await ref.putFile(File(_path), metadata);
      }
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

