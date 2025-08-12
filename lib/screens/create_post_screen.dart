// lib/screens/create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fouta_app/services/media_service.dart';
import 'package:fouta_app/features/creation/editor/video_editor.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:fouta_app/services/connectivity_provider.dart';
import 'package:fouta_app/widgets/fouta_button.dart';
import 'package:fouta_app/utils/snackbar.dart';
import 'package:fouta_app/utils/overlays.dart';

import 'package:fouta_app/main.dart'; // Import APP_ID
import 'package:fouta_app/constants/media_limits.dart'; // Provides kMaxVideoBytes

class CreatePostScreen extends StatefulWidget {
  final String? postId;
  final String? initialContent;
  final String? initialMediaUrl;
  final String? initialMediaType;
  final String? initialImagePath;
  final String? initialVideoPath;
  final bool isStory;

  const CreatePostScreen({
    super.key,
    this.postId,
    this.initialContent,
    this.initialMediaUrl,
    this.initialMediaType,
    this.initialImagePath,
    this.initialVideoPath,
    this.isStory = false,
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

  final MediaService _mediaService = MediaService();

  // Flag to control preview dialog when new media is selected
  bool _isPreviewing = false;


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
    if (widget.initialImagePath != null) {
      final file = XFile(widget.initialImagePath!);
      _selectedMediaFiles.add(file);
      _mediaTypesList.add('image');
      _videoAspectRatios.add(null);
      _selectedMediaBytesList.add(null);
    }
    if (widget.initialVideoPath != null) {
      final file = XFile(widget.initialVideoPath!);
      _selectedMediaFiles.add(file);
      _mediaTypesList.add('video');
      _videoAspectRatios.add(null);
      _selectedMediaBytesList.add(null);
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
        backgroundColor: msg.contains('successful') ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
      ),
    );

    final lower = msg.toLowerCase();
    final isError = lower.contains('fail') || lower.contains('error');
    AppSnackBar.show(context, msg, isError: isError);

  }

  Future<void> _pickMedia(ImageSource source, {bool isVideo = false}) async {
    if (_isUploading) {
      _showMessage('Upload in progress. Please wait.');
      return;
    }
    final attachment = isVideo
        ? await _mediaService.pickVideo(source: source)
        : await _mediaService.pickImage(source: source);
    if (attachment == null) {
      _showMessage('No media selected.');
      return;
    }

    // Always work with XFile objects for media attachments.
    // Convert to a dart:io File for VideoEditor operations.
    XFile file = attachment.file;
    if (isVideo) {
      final editor = VideoEditor();
      final duration = Duration(milliseconds: attachment.durationMs ?? 0);
      final File videoFile = File(file.path); // VideoEditor expects File
      final File trimmedFile = await editor.trim(
        videoFile,
        const Duration(seconds: 0),
        duration,
      );
      file = XFile(trimmedFile.path); // Convert back to XFile
    }

    setState(() {
      _selectedMediaFiles.add(file);
      _mediaTypesList.add(attachment.type);
      _videoAspectRatios.add(isVideo ? attachment.aspectRatio : null);
      _selectedMediaBytesList.add(attachment.bytes);
    });

    final proceed = await _showPreviewDialog();
    if (!proceed) {
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
        final attachment = MediaAttachment(
          file: file,
          type: type,
          aspectRatio: aspect,
          bytes: _selectedMediaBytesList[i],
        );
        try {
          final uploaded = await _mediaService.upload(attachment);
          attachments.add({
            'type': uploaded.type,
            'url': uploaded.url,
            if (uploaded.thumbUrl != null) 'thumbUrl': uploaded.thumbUrl,
            if (uploaded.aspectRatio != null) 'aspectRatio': uploaded.aspectRatio,
            if (uploaded.durationMs != null) 'durationMs': uploaded.durationMs,
            if (uploaded.width != null) 'width': uploaded.width,
            if (uploaded.height != null) 'height': uploaded.height,
          });
        } on FirebaseException catch (e) {
          _showMessage('Media upload failed: ${e.message}');
          setState(() {
            _isUploading = false;
          });
          return;
        }
        uploadedCount++;
        if (mounted) {
          setState(() {
            _uploadProgress = uploadedCount / _selectedMediaFiles.length;
          });
        }
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
          'bookmarks': [],
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
    final proceed = await showFoutaDialog<bool>(
      context: context,
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
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                        child: Center(
                          child: Builder(
                            builder: (context) => Icon(
                              Icons.videocam,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
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
    final userName = FirebaseAuth.instance.currentUser?.displayName ?? 'Fouta';
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
                color: _message!.contains('successful') ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.errorContainer,
                child: Center(
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _message!.contains('successful') ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _postContentController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: "What's on your mind, $userName?",
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
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
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
        color: Theme.of(context).colorScheme.onSurface,
        child: Center(
          child: Builder(
            builder: (context) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.play_circle_fill, color: Theme.of(context).colorScheme.onPrimary, size: 50),
                const SizedBox(height: 8),
                Text(
                  'Video Preview (Not supported on Web yet)',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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
        color: Theme.of(context).colorScheme.onSurface,
        child: Center(
          child: Builder(
            builder: (context) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_fill, color: Theme.of(context).colorScheme.onPrimary, size: 50),
                const SizedBox(height: 8),
                Text(
                  'Video Selected',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Center(child: Icon(Icons.broken_image, color: Theme.of(context).colorScheme.outline, size: 50)),
            ),
          ),
        );
      case 'video':
        return Container(
          height: 200,
          color: Theme.of(context).colorScheme.onSurface,
          child: Center(
            child: Builder(
              builder: (context) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_fill, color: Theme.of(context).colorScheme.onPrimary, size: 50),
                  const SizedBox(height: 8),
                  Text(
                    'Existing Video',
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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
          color: Theme.of(context).colorScheme.onSurface,
          child: Center(
            child: Builder(
              builder: (context) => Icon(
                Icons.play_circle_fill,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 50,
              ),
            ),
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