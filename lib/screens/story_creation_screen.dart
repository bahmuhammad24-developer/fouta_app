import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:fouta_app/utils/firestore_paths.dart';
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

  StoryCreationScreen({
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
  bool _isUploading = false;

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
      body: Center(
        child: _isUploading
            ? const CircularProgressIndicator(color: Colors.white)
            : preview,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to post stories')),
        );
      }
      return;
    }

    setState(() => _isUploading = true);
    try {
      final mediaFile = File(widget.initialMediaPath);
      final String ext = widget.isVideo ? 'mp4' : 'jpg';
      final String storagePath =
          'stories/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      final metadata = SettableMetadata(
        contentType: widget.isVideo ? 'video/mp4' : 'image/jpeg',
      );
      final uploadTask = ref.putFile(mediaFile, metadata);
      await uploadTask;
      final mediaUrl = await ref.getDownloadURL();

      // Fetch author details for display in story tray.
      // Some authentication methods (e.g., phone sign-in) don't provide an
      // email address.  The previous implementation attempted to split the
      // email to derive a username which resulted in a crash when `email` was
      // null.  Derive the display name defensively instead.
      String displayName;
      if (user.email != null) {
        displayName = user.email!.split('@').first;
      } else {
        displayName = user.displayName ?? user.phoneNumber ?? 'User';
      }
      String imageUrl = '';
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection(FirestorePaths.users())
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          displayName = data['displayName'] ?? displayName;
          imageUrl = data['profileImageUrl'] ?? '';
        }
      } catch (_) {}

      final storiesRef =
          FirebaseFirestore.instance.collection(FirestorePaths.stories());
      final storyDoc = storiesRef.doc(user.uid);

      await storyDoc.set({
        'authorId': user.uid,
        'authorName': displayName,
        'authorImageUrl': imageUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(hours: 24))),
        'viewedBy': [],
      }, SetOptions(merge: true));

      await storyDoc.collection('slides').add({
        'authorId': user.uid,
        'mediaUrl': mediaUrl,
        'mediaType': widget.isVideo ? 'video' : 'image',
        'createdAt': FieldValue.serverTimestamp(),
        'viewers': [],
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error uploading story: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload story')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}

