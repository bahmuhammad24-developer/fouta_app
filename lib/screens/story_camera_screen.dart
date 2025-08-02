import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// Import the story creation screen from the project root instead of
// the screens directory. The file lives at lib/story_creation_screen.dart.
// Import the story creation screen from the screens directory. The file lives
// at lib/screens/story_creation_screen.dart, so it can be imported via the
// package namespace under screens.
import 'package:fouta_app/screens/story_creation_screen.dart';

/// A camera interface for creating a story. Users can tap the shutter button
/// to take a photo or press and hold to record a video. They can also
/// choose media from their gallery. After capturing or selecting media,
/// the user is navigated to [StoryCreationScreen] for editing and posting.
class StoryCameraScreen extends StatefulWidget {
  const StoryCameraScreen({super.key});

  @override
  State<StoryCameraScreen> createState() => _StoryCameraScreenState();
}

class _StoryCameraScreenState extends State<StoryCameraScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isRecording = false;
  DateTime? _recordStart;

  Future<void> _takePhoto() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera);
    if (file != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryCreationScreen(
            initialMediaPath: file.path,
            isVideo: false,
          ),
        ),
      );
    }
  }

  Future<void> _takeVideo() async {
    final XFile? file = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 15),
    );
    if (file != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryCreationScreen(
            initialMediaPath: file.path,
            isVideo: true,
          ),
        ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryCreationScreen(
            initialMediaPath: file.path,
            isVideo: false,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // TODO: integrate live camera preview using the camera package.
          Positioned.fill(
            child: Container(color: Colors.black),
          ),
          // Top controls: flash, switch camera (placeholders)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.flash_off, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.cameraswitch, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          // Bottom controls: gallery and shutter button
          Positioned(
            bottom: 40 + MediaQuery.of(context).padding.bottom,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.photo_library, color: Colors.white),
                      onPressed: _pickFromGallery,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _takePhoto,
                  onLongPressStart: (_) {
                    setState(() {
                      _isRecording = true;
                      _recordStart = DateTime.now();
                    });
                  },
                  onLongPressEnd: (_) async {
                    // Only trigger video recording if press lasted > 0.2 seconds
                    if (_isRecording) {
                      setState(() => _isRecording = false);
                      await _takeVideo();
                    }
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording ? Colors.red : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  StoryCreationScreen({required String initialMediaPath, required bool isVideo}) {}
}