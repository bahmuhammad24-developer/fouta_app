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
  // Support multiple media attachments
  final List<XFile> _selectedMediaFiles = [];
  final List<Uint8List?> _selectedMediaBytesList = [];
  final List<String> _mediaTypesList = [];
  final List<double?> _videoAspectRatios = [];
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  String? _message;
  // Existing media for editing posts (list of maps with url and type)
  List<Map<String, dynamic>>? _existingMedia;

  final ImagePicker _picker = ImagePicker();

  // Flag to control preview dialog when new media is selected
  bool _isPreviewing = false;

  // Media upload limitations
  // Increased limits to allow larger video uploads.
  // Most modern devices record videos well above 15 MB, which previously
  // prevented uploads. Allow up to ~100 MB and five minutes duration.
  static const int _maxVideoFileSize = 100 * 1024 * 1024; // 100 MB
  static const int _maxVideoDurationSeconds = 300; // 5 minutes max

  @override
  void initState() {
    super.initState();
    if (widget.postId != null) {
      _postContentController.text = widget.initialContent ?? '';
      // Prepare existing media for editing
      if (widget.initialMediaUrl != null && widget.initialMediaUrl!.isNotEmpty) {
        _existingMedia = [
          {
            'url': widget.initialMediaUrl,
            'type': widget.initialMediaType ?? '',
            'aspectRatio': null,
          }
        ];
      }
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

    if (pickedFile == null) {
      _showMessage('No media selected.');
      return;
    }

    // Validate video size and duration for videos on non-web platforms
    double? aspectRatio;
    if (isVideo && !kIsWeb) {
      final fileSize = File(pickedFile.path).lengthSync();
      if (fileSize > _maxVideoFileSize) {
        _showMessage('Video is too large. Please select a video under 100 MB.');
        return;
      }
      final player = Player();
      // Open the video without autoplay to avoid background audio during
      // metadata extraction.  `play: false` prevents the player from
      // immediately starting playback which previously caused the selected
      // video's audio to play even though the user had not yet posted it.
      await player.open(Media(pickedFile.path), play: false);
      final duration = player.state.duration;
      await player.stream.width.firstWhere((width) => width != null);
      final width = player.state.width;
      final height = player.state.height;
      if (width != null && height != null && height > 0) {
        aspectRatio = width / height;
      }
      if (duration.inSeconds > _maxVideoDurationSeconds) {
        await player.dispose();
        _showMessage('Video is too long. Please select a video under 5 minutes.');
        return;
      }
      await player.dispose();
    }

    // Read bytes if on web for preview
    Uint8List? bytesForPreview;
    if (kIsWeb) {
      bytesForPreview = await pickedFile.readAsBytes();
    }

    // Add to lists temporarily for preview; if cancelled, remove later
    setState(() {
      _selectedMediaFiles.add(pickedFile!);
      _mediaTypesList.add(isVideo ? 'video' : 'image');
      _videoAspectRatios.add(aspectRatio);
      _selectedMediaBytesList.add(bytesForPreview);
    });

    // Show preview for the latest media and ask for confirmation
    final proceed = await _showPreviewDialog();
    if (!proceed) {
      // Remove the last added media if user cancels
      setState(() {
        _selectedMediaFiles.removeLast();
        _mediaTypesList.removeLast();
        _videoAspectRatios.removeLast();
        _selectedMediaBytesList.removeLast();
        _message = 'Media selection cancelled.';
      });
    } else {
      setState(() {
        _message = null;
      });
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

    if (_postContentController.text.trim().isEmpty && _selectedMediaFiles.isEmpty && (_existingMedia == null || _existingMedia!.isEmpty)) {
      _showMessage('Post cannot be empty without text, image, or video.');
      return;
    }

    // Prevent media uploads while offline. Text‑only posts can still be added offline via Firestore persistence.
    final connectivity = context.read<ConnectivityProvider>();
    if (!connectivity.isOnline && _selectedMediaFiles.isNotEmpty) {
      _showMessage('You are offline. Cannot upload media.');
      return;
    }

    // Upload each selected media and build attachments list
    List<Map<String, dynamic>> attachments = [];
    // Include existing media (if editing) so that they persist
    if (_existingMedia != null) {
      attachments.addAll(_existingMedia!);
    }

    if (_selectedMediaFiles.isNotEmpty) {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });
      int uploadedCount = 0;
      for (int i = 0; i < _selectedMediaFiles.length; i++) {
        final XFile file = _selectedMediaFiles[i];
        final String type = _mediaTypesList[i];
        final double? aspect = _videoAspectRatios[i];
        String fileName = file.name;
        Uint8List? bytesToUpload;
        File? fileToUpload;

        if (kIsWeb) {
          bytesToUpload = await file.readAsBytes();
        } else {
          if (type == 'image') {
            final originalBytes = await file.readAsBytes();
            final img.Image? decoded = img.decodeImage(originalBytes);
            if (decoded != null) {
              final compressed = img.encodeJpg(decoded, quality: 80);
              bytesToUpload = Uint8List.fromList(compressed);
            } else {
              fileToUpload = File(file.path);
            }
          } else {
            fileToUpload = File(file.path);
          }
        }

        final String fileExtension = fileName.split('.').last;
        final String storagePath = '${type}s/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${user.uid}_$i.$fileExtension';
        final storageRef = FirebaseStorage.instance.ref().child(storagePath);

        // Ensure a correct content type so that Firebase Storage serves the
        // file with the proper headers.  Without this, uploaded videos can be
        // stored as `application/octet-stream`, preventing some clients from
        // recognizing them as playable media.
        final SettableMetadata metadata = SettableMetadata(
          contentType: type == 'video' ? 'video/mp4' : 'image/jpeg',
        );

        UploadTask uploadTask;
        if (bytesToUpload != null) {
          uploadTask = storageRef.putData(bytesToUpload, metadata);
        } else if (fileToUpload != null) {
          uploadTask = storageRef.putFile(fileToUpload, metadata);
        } else {
          _showMessage('Invalid media data for upload.');
          setState(() { _isUploading = false; });
          return;
        }

        // Update overall progress based on each file
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (mounted) {
            setState(() {
              // Average progress across all uploads
              _uploadProgress = ((uploadedCount + snapshot.bytesTransferred / snapshot.totalBytes) / _selectedMediaFiles.length);
            });
          }
        });

        String? url;
        try {
          await uploadTask;
          url = await storageRef.getDownloadURL();
        } on FirebaseException catch (e) {
          _showMessage('Media upload failed: ${e.message}');
          setState(() { _isUploading = false; });
          return;
        }
        if (url != null) {
          attachments.add({
            'url': url,
            'type': type,
            if (type == 'video') 'aspectRatio': aspect,
          });
        }
        uploadedCount++;
      }
      // Reset uploading state after all uploads
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
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
        // Determine summary media for backward compatibility (first attachment)
        String? summaryUrl;
        String? summaryType;
        double? summaryAspect;
        if (attachments.isNotEmpty) {
          summaryUrl = attachments.first['url'] as String;
          summaryType = attachments.first['type'] as String;
          summaryAspect = attachments.first['aspectRatio'] as double?;
        }
        final postData = {
          'content': _postContentController.text.trim(),
          'media': attachments,
          'mediaUrl': summaryUrl,
          'mediaType': summaryType,
          'authorId': user.uid,
          'authorDisplayName': authorDisplayName,
          'authorProfileImageUrl': authorProfileImageUrl,
          'timestamp': FieldValue.serverTimestamp(),
          'likes': [],
          'shares': 0,
          'calculatedEngagement': _calculateEngagement(0, 0, 0),
          'type': 'original',
          'postVisibility': postVisibility,
          if (summaryType == 'video') 'aspectRatio': summaryAspect,
        };
        final newPostRef = await FirebaseFirestore.instance
            .collection('artifacts/$APP_ID/public/data/posts')
            .add(postData);
        _showMessage('Post added successfully!');
        _updateEngagementScore(newPostRef.id);
      } else {
        // For editing, update content and append new attachments while preserving existing ones
        await FirebaseFirestore.instance
            .collection('artifacts/$APP_ID/public/data/posts')
            .doc(widget.postId)
            .update({
          'content': _postContentController.text.trim(),
          'media': attachments,
        });
        _showMessage('Post updated successfully!');
        _updateEngagementScore(widget.postId!);
      }

      _postContentController.clear();
      setState(() {
        _selectedMediaFiles.clear();
        _selectedMediaBytesList.clear();
        _mediaTypesList.clear();
        _videoAspectRatios.clear();
        _existingMedia = null;
        _uploadProgress = 0.0;
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
                // Display preview for the last selected media
                Builder(builder: (context) {
                  if (_selectedMediaFiles.isNotEmpty) {
                    final int idx = _selectedMediaFiles.length - 1;
                    final String type = _mediaTypesList[idx];
                    if (type == 'image') {
                      if (kIsWeb) {
                        final bytes = _selectedMediaBytesList[idx];
                        return SizedBox(
                          width: 300,
                          height: 200,
                          child: bytes != null
                              ? Image.memory(bytes, fit: BoxFit.contain)
                              : const SizedBox.shrink(),
                        );
                      } else {
                        final file = File(_selectedMediaFiles[idx].path);
                        return SizedBox(
                          width: 300,
                          height: 200,
                          child: Image.file(file, fit: BoxFit.contain),
                        );
                      }
                    } else if (type == 'video') {
                      return Container(
                        width: 300,
                        height: 200,
                        color: Colors.black12,
                        child: const Center(
                          child: Icon(Icons.videocam, size: 64, color: Colors.grey),
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                }),
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
            // Show previews for selected and existing media
            if ((_selectedMediaFiles.isNotEmpty || (_existingMedia != null && _existingMedia!.isNotEmpty)))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMediaPreviewList(),
                  if (!_isUploading)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedMediaFiles.clear();
                            _selectedMediaBytesList.clear();
                            _mediaTypesList.clear();
                            _videoAspectRatios.clear();
                            _existingMedia = null;
                            _message = 'Media cleared.';
                          });
                        },
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('Clear Media'),
                      ),
                    ),
                ],
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

  /// Builds a horizontal list of media previews for both existing and newly selected media.
  Widget _buildMediaPreviewList() {
    final List<Widget> items = [];
    // Add existing media previews first
    if (_existingMedia != null) {
      for (final media in _existingMedia!) {
        final String type = media['type'] ?? '';
        final String url = media['url'] ?? '';
        items.add(Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: SizedBox(
            width: 150,
            height: 150,
            child: _buildMediaDisplayExisting(type, url),
          ),
        ));
      }
    }
    // Add new selected media previews
    for (int i = 0; i < _selectedMediaFiles.length; i++) {
      final type = _mediaTypesList[i];
      Widget preview;
      if (type == 'image') {
        if (kIsWeb) {
          final bytes = _selectedMediaBytesList[i];
          preview = bytes != null
              ? Image.memory(bytes, width: 150, height: 150, fit: BoxFit.cover)
              : const SizedBox.shrink();
        } else {
          final file = File(_selectedMediaFiles[i].path);
          preview = Image.file(file, width: 150, height: 150, fit: BoxFit.cover);
        }
      } else {
        preview = Container(
          width: 150,
          height: 150,
          color: Colors.black,
          child: const Center(
            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
          ),
        );
      }
      items.add(Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: preview,
        ),
      ));
    }
    return SizedBox(
      height: 170,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: items,
      ),
    );
  }
}