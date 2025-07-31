// lib/screens/create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:media_kit/media_kit.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:fouta_app/services/connectivity_provider.dart';
import 'package:fouta_app/widgets/fouta_button.dart';

import 'package:fouta_app/main.dart'; // Import APP_ID

class CreatePostScreen extends StatefulWidget {
  final String? postId;
  final String? initialContent;
  final String? initialMediaUrl;
  final String? initialMediaType;

  const CreatePostScreen({
    super.key,
    this.postId,
    this.initialContent,
    this.initialMediaUrl,
    this.initialMediaType,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _postContentController = TextEditingController();
  XFile? _selectedMediaFile;
  Uint8List? _selectedMediaBytes;
  String _mediaType = '';
  double? _videoAspectRatio;
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  String? _message;
  String? _currentMediaUrl;

  final ImagePicker _picker = ImagePicker();

  // Flag to control preview dialog when new media is selected
  bool _isPreviewing = false;

  // Media upload limitations
  static const int _maxVideoFileSize = 15 * 1024 * 1024; // 15 MB
  static const int _maxVideoDurationSeconds = 60; // 60 seconds max

  @override
  void initState() {
    super.initState();
    if (widget.postId != null) {
      _postContentController.text = widget.initialContent ?? '';
      _currentMediaUrl = widget.initialMediaUrl;
      _mediaType = widget.initialMediaType ?? '';
    }
  }

  @override
  void dispose() {
    _postContentController.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    setState(() {
      _message = msg;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: msg.contains('successful') ? Colors.green : Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source, {bool isVideo = false}) async {
    if (_isUploading) {
      _showMessage('Upload in progress. Please wait.');
      return;
    }

    XFile? pickedFile;
    try {
      pickedFile = isVideo
          ? await _picker.pickVideo(source: source)
          : await _picker.pickImage(source: source);
    } catch (e) {
      _showMessage('Error picking media: $e');
      return;
    }

    // Validate video size and duration constraints for non-web platforms
    double? aspectRatio;
    if (isVideo && pickedFile != null && !kIsWeb) {
      final fileSize = File(pickedFile.path).lengthSync();
      if (fileSize > _maxVideoFileSize) {
        _showMessage('Video is too large. Please select a video under 15 MB.');
        return;
      }
      final player = Player();
      await player.open(Media(pickedFile.path));
      final duration = player.state.duration;
      // Wait for width to be available to compute aspect ratio
      await player.stream.width.firstWhere((width) => width != null);
      final width = player.state.width;
      final height = player.state.height;
      if (width != null && height != null && height > 0) {
        aspectRatio = width / height;
      }
      // Validate duration
      if (duration.inSeconds > _maxVideoDurationSeconds) {
        await player.dispose();
        _showMessage('Video is too long. Please select a video under 60 seconds.');
        return;
      }
      await player.dispose();
    }

    setState(() {
      if (pickedFile != null) {
        _selectedMediaFile = pickedFile;
        _message = null;
        _mediaType = isVideo ? 'video' : 'image';
        _videoAspectRatio = aspectRatio;
        _currentMediaUrl = null;

        if (kIsWeb) {
          pickedFile.readAsBytes().then((bytes) {
            setState(() {
              _selectedMediaBytes = bytes;
            });
          });
        }
      } else {
        _selectedMediaFile = null;
        _selectedMediaBytes = null;
        _mediaType = '';
        _videoAspectRatio = null;
        _message = 'No media selected.';
      }
    });

    // If a new media file was selected, show preview dialog and allow user to confirm or cancel.
    if (pickedFile != null) {
      final proceed = await _showPreviewDialog();
      if (!proceed) {
        // User cancelled posting; clear the selected media
        setState(() {
          _selectedMediaFile = null;
          _selectedMediaBytes = null;
          _mediaType = '';
          _videoAspectRatio = null;
          _currentMediaUrl = null;
          _message = 'Media selection cancelled.';
        });
      }
    }
  }

  int _calculateEngagement(int likes, int comments, int shares) {
    return (likes * 1 + comments * 2 + shares * 3);
  }

  Future<void> _updateEngagementScore(String postId) async {
    try {
      final postRef = FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/posts').doc(postId);
      final postDoc = await postRef.get();
      if (postDoc.exists) {
        final data = postDoc.data()!;
        final int likes = (data['likes'] as List?)?.length ?? 0;
        final commentsSnapshot = await postRef.collection('comments').get();
        final int comments = commentsSnapshot.docs.length;
        final int shares = data['shares'] ?? 0;

        final int newEngagement = _calculateEngagement(likes, comments, shares);
        await postRef.update({'calculatedEngagement': newEngagement});
      }
    } catch (e) {
      debugPrint('Error updating engagement score: $e');
    }
  }

  Future<void> _handlePostSubmission() async {
    setState(() {
      _message = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      _showMessage('Please log in or register to post.');
      return;
    }

    if (_postContentController.text.trim().isEmpty && _selectedMediaFile == null && _currentMediaUrl == null) {
      _showMessage('Post cannot be empty without text, image, or video.');
      return;
    }

    // Prevent media uploads while offline. Text‑only posts can still be added offline via Firestore persistence.
    final connectivity = context.read<ConnectivityProvider>();
    if (!connectivity.isOnline && _selectedMediaFile != null) {
      _showMessage('You are offline. Cannot upload media.');
      return;
    }

    String? mediaUrl = _currentMediaUrl;
    String currentMediaType = _mediaType;

    if (_selectedMediaFile != null) {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });
      try {
        String fileName = _selectedMediaFile!.name;
        Uint8List? bytesToUpload;
        File? fileToUpload;

        // Prepare bytes for upload. Compress images on non-web platforms.
        if (kIsWeb) {
          // On web, just read bytes directly
          bytesToUpload = await _selectedMediaFile!.readAsBytes();
        } else {
          if (_mediaType == 'image') {
            final originalBytes = await _selectedMediaFile!.readAsBytes();
            final img.Image? decoded = img.decodeImage(originalBytes);
            if (decoded != null) {
              final compressed = img.encodeJpg(decoded, quality: 80);
              bytesToUpload = Uint8List.fromList(compressed);
            } else {
              // Fallback to original file if decoding fails
              fileToUpload = File(_selectedMediaFile!.path);
            }
          } else {
            // For video, no compression; use the file directly
            fileToUpload = File(_selectedMediaFile!.path);
          }
        }

        final String fileExtension = fileName.split('.').last;
        final String storagePath = '${_mediaType}s/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${user.uid}.$fileExtension';
        final storageRef = FirebaseStorage.instance.ref().child(storagePath);

        UploadTask uploadTask;
        if (bytesToUpload != null) {
          uploadTask = storageRef.putData(bytesToUpload);
        } else if (fileToUpload != null) {
          uploadTask = storageRef.putFile(fileToUpload);
        } else {
          _showMessage('Invalid media data for upload.');
          setState(() { _isUploading = false; });
          return;
        }

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (mounted) {
            setState(() {
              _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
            });
          }
        });

        await uploadTask.whenComplete(() async {
          mediaUrl = await storageRef.getDownloadURL();
          currentMediaType = _mediaType;
          _showMessage('${_mediaType == 'image' ? 'Image' : 'Video'} uploaded successfully!');
        });
      } on FirebaseException catch (e) {
        _showMessage('Media upload failed: ${e.message}');
        setState(() {
          _isUploading = false;
        });
        return;
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }

    String authorDisplayName = user.email?.split('@')[0] ?? 'Anonymous';
    String authorProfileImageUrl = '';
    String postVisibility = 'everyone';
    try {
      final userDoc = await FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(user.uid).get();
      if (userDoc.exists) {
        authorDisplayName = userDoc.data()?['displayName'] ?? authorDisplayName;
        authorProfileImageUrl = userDoc.data()?['profileImageUrl'] ?? '';
        postVisibility = userDoc.data()?['postVisibility'] ?? 'everyone';
      }
    } catch (e) {
      debugPrint('Error fetching author display name: $e');
    }

    try {
      if (widget.postId == null) {
        final postData = {
          'content': _postContentController.text.trim(),
          'mediaUrl': mediaUrl,
          'mediaType': currentMediaType,
          'authorId': user.uid,
          'authorDisplayName': authorDisplayName,
          'authorProfileImageUrl': authorProfileImageUrl,
          'timestamp': FieldValue.serverTimestamp(),
          'likes': [],
          'shares': 0,
          'calculatedEngagement': _calculateEngagement(0, 0, 0),
          'type': 'original',
          'postVisibility': postVisibility,
          if (currentMediaType == 'video') 'aspectRatio': _videoAspectRatio,
        };
        final newPostRef = await FirebaseFirestore.instance
            .collection('artifacts/$APP_ID/public/data/posts')
            .add(postData);
        _showMessage('Post added successfully!');
        _updateEngagementScore(newPostRef.id);
      } else {
        await FirebaseFirestore.instance
            .collection('artifacts/$APP_ID/public/data/posts')
            .doc(widget.postId)
            .update({
          'content': _postContentController.text.trim(),
          'mediaUrl': mediaUrl,
          'mediaType': currentMediaType,
        });
        _showMessage('Post updated successfully!');
        _updateEngagementScore(widget.postId!);
      }

      _postContentController.clear();
      setState(() {
        _selectedMediaFile = null;
        _selectedMediaBytes = null;
        _mediaType = '';
        _currentMediaUrl = null;
        _uploadProgress = 0.0;
        _videoAspectRatio = null;
      });
      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (e) {
      _showMessage('Failed to save post: ${e.message}');
    } catch (e) {
      _showMessage('An unexpected error occurred: $e');
    }
  }

  /// Shows a simple preview dialog allowing the user to confirm or cancel posting.
  /// Returns true if the user chooses to proceed, false otherwise.
  Future<bool> _showPreviewDialog() async {
    // Avoid showing multiple preview dialogs simultaneously
    if (_isPreviewing) return false;
    _isPreviewing = true;
    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Preview'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_mediaType == 'image')
                  SizedBox(
                    width: 300,
                    height: 200,
                    child: kIsWeb
                        ? (_selectedMediaBytes != null
                            ? Image.memory(_selectedMediaBytes!, fit: BoxFit.contain)
                            : const SizedBox.shrink())
                        : (_selectedMediaFile != null
                            ? Image.file(File(_selectedMediaFile!.path), fit: BoxFit.contain)
                            : const SizedBox.shrink()),
                  )
                else if (_mediaType == 'video')
                  Container(
                    width: 300,
                    height: 200,
                    color: Colors.black12,
                    child: const Center(
                      child: Icon(Icons.videocam, size: 64, color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 16),
                // Caption field for editing during preview
                TextField(
                  controller: _postContentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add a caption...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: const Text('Post'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;
    _isPreviewing = false;
    return proceed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.postId == null ? 'Create New Post' : 'Edit Post'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_message != null)
              Container(
                padding: const EdgeInsets.all(8.0),
                color: _message!.contains('successful') ? Colors.green[100] : Colors.red[100],
                child: Center(
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _message!.contains('successful') ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _postContentController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'What\'s on your mind, Fouta?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            if (_selectedMediaBytes != null && kIsWeb)
              _buildMediaPreviewWeb(_mediaType, _selectedMediaBytes!)
            else if (_selectedMediaFile != null && !kIsWeb)
              _buildMediaPreviewMobile(_mediaType, _selectedMediaFile!.path)
            else if (_currentMediaUrl != null && _currentMediaUrl!.isNotEmpty)
              _buildMediaDisplayExisting(_mediaType, _currentMediaUrl!),
            if ((_selectedMediaFile != null || _currentMediaUrl != null) && !_isUploading)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedMediaFile = null;
                      _selectedMediaBytes = null;
                      _mediaType = '';
                      _currentMediaUrl = null;
                      _videoAspectRatio = null;
                      _message = 'Media cleared.';
                    });
                  },
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear Media'),
                ),
              ),
            if (_isUploading)
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[300],
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickMedia(ImageSource.gallery, isVideo: false),
                  icon: const Icon(Icons.image),
                  label: const Text('Image'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickMedia(ImageSource.gallery, isVideo: true),
                  icon: const Icon(Icons.videocam),
                  label: const Text('Video'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Use FoutaButton for submission to match the new design system
            SizedBox(
              width: double.infinity,
              child: FoutaButton(
                label: widget.postId == null ? 'Post to Fouta' : 'Save Changes',
                onPressed: _isUploading ? () {} : _handlePostSubmission,
                primary: true,
                expanded: true,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreviewWeb(String mediaType, Uint8List bytes) {
    if (mediaType == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.memory(
          bytes,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else if (mediaType == 'video') {
      return Container(
        height: 200,
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
              SizedBox(height: 8),
              Text(
                'Video Preview (Not supported on Web yet)',
                style: TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMediaPreviewMobile(String mediaType, String path) {
    if (mediaType == 'image') {
      return Image.file(
        File(path),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (mediaType == 'video') {
      return Container(
        height: 200,
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
              SizedBox(height: 8),
              Text(
                'Video Selected',
                style: TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMediaDisplayExisting(String mediaType, String mediaUrl) {
    switch (mediaType) {
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            mediaUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 200,
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50)),
            ),
          ),
        );
      case 'video':
        return Container(
          height: 200,
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
                SizedBox(height: 8),
                Text(
                  'Existing Video',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}