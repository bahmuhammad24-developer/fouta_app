import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
// Import the story creation screen widget used after capturing media.
import 'package:fouta_app/screens/story_creation_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fouta_app/utils/snackbar.dart';

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
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCamera = 0;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final statuses = await [Permission.camera, Permission.microphone].request();
    final cameraGranted =
        statuses[Permission.camera] == PermissionStatus.granted;
    final micGranted =
        statuses[Permission.microphone] == PermissionStatus.granted;
    if (!cameraGranted || !micGranted) {
      if (mounted) {
        AppSnackBar.show(context,
            'Camera and microphone permissions are required.',
            isError: true);
        Navigator.pop(context);
      }
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      _controller = CameraController(
        _cameras[_currentCamera],
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      // If the camera cannot be initialized, remain with a blank preview.
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final XFile file = await _controller!.takePicture();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryCreationScreen(
            initialMediaPath: file.path,
            isVideo: false,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Take photo error: $e');
    }
  }

  Future<void> _startVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      await _controller!.startVideoRecording();
    } catch (e) {
      debugPrint('Start recording error: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) return;
    try {
      final XFile file = await _controller!.stopVideoRecording();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryCreationScreen(
            initialMediaPath: file.path,
            isVideo: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Stop recording error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    final statuses = await [Permission.photos, Permission.storage].request();
    final photosGranted =
        statuses[Permission.photos] == PermissionStatus.granted;
    final storageGranted =
        statuses[Permission.storage] == PermissionStatus.granted;
    if (!photosGranted && !storageGranted) {
      if (mounted) {
        AppSnackBar.show(context, 'Photo library permission is required.',
            isError: true);
      }
      return;
    }

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

  void _switchCamera() {
    if (_cameras.length < 2) return;
    _currentCamera = (_currentCamera + 1) % _cameras.length;
    _controller?.dispose();
    _controller = null;
    setState(() {});
    _initCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onSurface,
      body: Stack(
        children: [
          Positioned.fill(
            child: (_controller != null && _controller!.value.isInitialized)
                ? CameraPreview(_controller!)
                : Container(color: Theme.of(context).colorScheme.onSurface),
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
                  icon: Icon(Icons.flash_off, color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.cameraswitch, color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: _switchCamera,
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

                      icon: Icon(Icons.photo_library, color: Theme.of(context).colorScheme.onPrimary),

                      onPressed: _pickFromGallery,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: _takePhoto,
                  onLongPressStart: (_) {
                    setState(() => _isRecording = true);
                    _startVideoRecording();
                  },
                  onLongPressEnd: (_) async {
                    if (_isRecording) {
                      setState(() => _isRecording = false);
                      await _stopVideoRecording();
                    }
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onPrimary,
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onPrimary,

                Semantics(
                  label: 'Capture story',
                  button: true,
                  child: GestureDetector(
                    onTap: _takePhoto,
                    onLongPressStart: (_) {
                      setState(() => _isRecording = true);
                      _startVideoRecording();
                    },
                    onLongPressEnd: (_) async {
                      if (_isRecording) {
                        setState(() => _isRecording = false);
                        await _stopVideoRecording();
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
