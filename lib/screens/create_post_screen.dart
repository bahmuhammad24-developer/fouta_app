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
      if (isVideo) {
        pickedFile = await _picker.pickVideo(source: source);
      } else {
        pickedFile = await _picker.pickImage(source: source);
      }
    } catch (e) {
      _showMessage('Error picking media: $e');
      return;
    }

    double? aspectRatio;
    if (isVideo && pickedFile != null && !kIsWeb) {
      final player = Player();
      await player.open(Media(pickedFile.path));
      // Wait for player to get video properties
      await player.stream.width.firstWhere((width) => width != null);
      final width = player.state.width;
      final height = player.state.height;
      if (width != null && height != null && height > 0) {
        aspectRatio = width / height;
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

    String? mediaUrl = _currentMediaUrl;
    String currentMediaType = _mediaType;

    if (_selectedMediaFile != null) {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });
      try {
        String fileName = _selectedMediaFile!.name;
        File? fileToUpload;
        Uint8List? bytesToUpload;

        if (kIsWeb) {
          bytesToUpload = await _selectedMediaFile!.readAsBytes();
        } else {
          fileToUpload = File(_selectedMediaFile!.path);
        }

        final String fileExtension = fileName.split('.').last;
        final String storagePath = '${_mediaType}s/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${user.uid}.$fileExtension';
        final storageRef = FirebaseStorage.instance.ref().child(storagePath);

        UploadTask uploadTask;
        if (kIsWeb && bytesToUpload != null) {
          uploadTask = storageRef.putData(bytesToUpload);
        } else if (fileToUpload != null) {
          uploadTask = storageRef.putFile(fileToUpload);
        } else {
          _showMessage('Invalid media data for upload.');
          setState(() { _isUploading = false; });
          return;
        }

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
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
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _handlePostSubmission,
              icon: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.send),
              label: Text(widget.postId == null ? 'Post to Fouta' : 'Save Changes'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
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