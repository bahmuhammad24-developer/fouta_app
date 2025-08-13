import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:fouta_app/services/media_service.dart';
import 'package:fouta_app/utils/firestore_paths.dart';

import 'drafts_service.dart';
import 'scheduling_service.dart';

/// Experimental composer with draft and scheduling support.
class ComposerV2Screen extends StatefulWidget {
  const ComposerV2Screen({super.key});

  static const route = '/composeV2';

  @override
  State<ComposerV2Screen> createState() => _ComposerV2ScreenState();
}

/// Returns routes for Composer V2.
Map<String, WidgetBuilder> composerV2Routes() {
  return {ComposerV2Screen.route: (_) => const ComposerV2Screen()};
}

class _ComposerV2ScreenState extends State<ComposerV2Screen> {
  final _textController = TextEditingController();
  final _mediaService = MediaService();
  final _draftsService = DraftsService();
  final _schedulingService = SchedulingService();
  final List<MediaAttachment> _attachments = [];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final att = await _mediaService.pickImage();
    if (att != null) setState(() => _attachments.add(att));
  }

  Future<void> _pickVideo() async {
    final att = await _mediaService.pickVideo();
    if (att != null) setState(() => _attachments.add(att));
  }

  Future<List<String>> _uploadMedia() async {
    final urls = <String>[];
    for (final att in _attachments) {
      final uploaded = await _mediaService.upload(att);
      urls.add(uploaded.url);
    }
    return urls;
  }

  Future<void> _saveDraft() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final urls = await _uploadMedia();
    final id = const Uuid().v4();
    await _draftsService.saveDraft(
      user.uid,
      id,
      content: _textController.text,
      media: urls,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Draft saved')));
  }

  Future<void> _schedule() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    final publishAt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final urls = await _uploadMedia();
    final id = const Uuid().v4();
    await _schedulingService.schedulePost(
      user.uid,
      id,
      publishAt,
      {'content': _textController.text, 'media': urls},
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Post scheduled')));
  }

  Future<void> _postNow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final urls = await _uploadMedia();
    await FirebaseFirestore.instance.collection(FirestorePaths.posts()).add({
      'authorId': user.uid,
      'content': _textController.text,
      'media': urls,
      'timestamp': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Posted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Composer V2')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration:
                  const InputDecoration(hintText: "What's happening?"),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _attachments
                  .map((a) => Chip(label: Text(a.type)))
                  .toList(),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                ),
                IconButton(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.videocam),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _saveDraft,
                  child: const Text('Save Draft'),
                ),
                ElevatedButton(
                  onPressed: _schedule,
                  child: const Text('Schedule'),
                ),
                ElevatedButton(
                  onPressed: _postNow,
                  child: const Text('Post Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
