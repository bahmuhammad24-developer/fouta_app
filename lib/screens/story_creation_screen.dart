// lib/screens/story_creation_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/main.dart';
import 'package:image_picker/image_picker.dart';

class StoryCreationScreen extends StatefulWidget {
  const StoryCreationScreen({super.key});

  @override
  State<StoryCreationScreen> createState() => _StoryCreationScreenState();
}

class _StoryCreationScreenState extends State<StoryCreationScreen> {
  File? _mediaFile;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _mediaFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _postStory() async {
    if (_mediaFile == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('stories_media/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final uploadTask = storageRef.putFile(_mediaFile!);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final userDoc = await FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(user.uid).get();
      final userData = userDoc.data();

      final storyRef = FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/stories').doc(user.uid);
      final storySlideRef = storyRef.collection('slides').doc();

      final batch = FirebaseFirestore.instance.batch();

      batch.set(storyRef, {
        'authorName': userData?['displayName'] ?? 'User',
        'authorImageUrl': userData?['profileImageUrl'] ?? '',
        'lastUpdated': FieldValue.serverTimestamp(),
        'viewedBy': [],
      }, SetOptions(merge: true));

      batch.set(storySlideRef, {
        'mediaUrl': downloadUrl,
        'mediaType': 'image',
        'createdAt': FieldValue.serverTimestamp(),
        'viewers': [],
      });
      
      await batch.commit();

      if(mounted) Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post story: $e')));
    } finally {
      if(mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: _mediaFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_library, color: Colors.white, size: 60),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  const Text('Pick from Gallery', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 40),
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white, size: 60),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  const Text('Take Photo', style: TextStyle(color: Colors.white)),
                ],
              )
            : Stack(
              fit: StackFit.expand,
              children: [
                Image.file(_mediaFile!, fit: BoxFit.contain),
                if(_isUploading) const Center(child: CircularProgressIndicator()),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _postStory,
                    icon: const Icon(Icons.send),
                    label: const Text('Post Story'),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}