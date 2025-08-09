// lib/widgets/share_post_dialog.dart
import 'package:flutter/material.dart';

class SharePostDialog extends StatefulWidget {
  final Map<String, dynamic> originalPostData;
  final String? initialContent;

  const SharePostDialog({
    super.key, 
    required this.originalPostData,
    this.initialContent,
  });

  @override
  State<SharePostDialog> createState() => _SharePostDialogState();
}

class _SharePostDialogState extends State<SharePostDialog> {
  final TextEditingController _shareContentController = TextEditingController();
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialContent != null;
    _shareContentController.text = widget.initialContent ?? '';
  }

  @override
  void dispose() {
    _shareContentController.dispose();
    super.dispose();
  }

  Widget _buildMediaDisplay(String mediaType, String mediaUrl) {
    switch (mediaType) {
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            mediaUrl,
            width: double.infinity,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 150,
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Center(child: Icon(Icons.broken_image, color: Theme.of(context).colorScheme.outline, size: 40)),
            ),
          ),
        );
      case 'video':
        return Container(
          width: double.infinity,
          height: 150,
          color: Theme.of(context).colorScheme.onSurface,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_fill, color: Theme.of(context).colorScheme.onPrimary, size: 40),
                SizedBox(height: 8),
                Text(
                  'Video Preview',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 10),
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

  @override
  Widget build(BuildContext context) {
    final String originalPostContent = widget.originalPostData['content'] ?? '';
    final String originalPostMediaUrl = widget.originalPostData['mediaUrl'] ?? '';
    final String originalPostMediaType = widget.originalPostData['mediaType'] ?? 'text';
    final String originalPostAuthorDisplayName = widget.originalPostData['authorDisplayName'] ?? 'Original Author';

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Post' : 'Share Post'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
          minHeight: MediaQuery.of(context).size.height * 0.3,
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.75,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _shareContentController,
                  maxLines: 3,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: _isEditing ? 'Edit your thoughts' : 'Add your thoughts (optional)',
                    border: const OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                const Text('Original Post:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline[100],
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Theme.of(context).colorScheme.surfaceVariant!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'by $originalPostAuthorDisplayName',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline[700]),
                      ),
                      const SizedBox(height: 4),
                      if (originalPostMediaUrl.isNotEmpty)
                        _buildMediaDisplay(originalPostMediaType, originalPostMediaUrl),
                      if (originalPostMediaUrl.isNotEmpty) const SizedBox(height: 8),
                      if (originalPostContent.isNotEmpty)
                        Text(
                          originalPostContent,
                          style: const TextStyle(fontSize: 14),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(null);
          },
        ),
        ElevatedButton(
          child: Text(_isEditing ? 'Save' : 'Share'),
          onPressed: () {
            Navigator.of(context).pop(_shareContentController.text.trim());
          },
        ),
      ],
    );
  }
}