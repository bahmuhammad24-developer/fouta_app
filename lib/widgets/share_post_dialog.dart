// lib/widgets/share_post_dialog.dart
import 'package:flutter/material.dart';

class SharePostDialog extends StatefulWidget {
  final Map<String, dynamic> originalPostData;

  const SharePostDialog({super.key, required this.originalPostData});

  @override
  State<SharePostDialog> createState() => _SharePostDialogState();
}

class _SharePostDialogState extends State<SharePostDialog> {
  final TextEditingController _shareContentController = TextEditingController();

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
            width: double.infinity, // This is fine if parent provides finite width
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 150,
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
            ),
          ),
        );
      case 'video':
        return Container(
          width: double.infinity, // This is fine if parent provides finite width
          height: 150,
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
                SizedBox(height: 8),
                Text(
                  'Video Preview',
                  style: TextStyle(color: Colors.white, fontSize: 10),
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
      title: const Text('Share Post'),
      // Applying a more robust ConstrainedBox to control the overall size of the dialog content
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6, // Max 60% of screen height
          minHeight: MediaQuery.of(context).size.height * 0.3, // Min 30% of screen height
          maxWidth: MediaQuery.of(context).size.width * 0.8, // Max 80% of screen width
        ),
        child: SingleChildScrollView(
          // Use a SizedBox to explicitly give the content a finite width
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.75, // Explicitly set width, slightly less than dialog maxWidth
            child: Column(
              mainAxisSize: MainAxisSize.min, // Ensure column takes minimum space required by its children
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _shareContentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Add your thoughts (optional)',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                const Text('Original Post:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'by $originalPostAuthorDisplayName',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
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
          child: const Text('Share'),
          onPressed: () {
            Navigator.of(context).pop(_shareContentController.text.trim());
          },
        ),
      ],
    );
  }
}
