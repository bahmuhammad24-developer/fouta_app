// lib/widgets/post_card_widget.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fouta_app/widgets/video_player_widget.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:fouta_app/utils/date_utils.dart';

import 'package:fouta_app/main.dart'; // Import APP_ID
import 'package:fouta_app/screens/create_post_screen.dart';
import 'package:fouta_app/screens/profile_screen.dart';
// Use the unified MediaViewer instead of separate full screen image/video widgets
import 'package:fouta_app/widgets/media_viewer.dart';
import 'package:fouta_app/widgets/share_post_dialog.dart';
import 'package:fouta_app/widgets/fouta_card.dart';

class PostCardWidget extends StatefulWidget {
  final Map<String, dynamic> post;
  final String postId;
  final User? currentUser;
  final String appId;
  final Function(String) onMessage;
  final bool isDataSaverOn;
  final bool isOnMobileData;

  const PostCardWidget({
    super.key,
    required this.post,
    required this.postId,
    required this.currentUser,
    required this.appId,
    required this.onMessage,
    required this.isDataSaverOn,
    required this.isOnMobileData,
  });

  @override
  State<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget> {
  final TextEditingController _commentInputController = TextEditingController();
  bool _showComments = false;
  bool _isPostVisible = false;

  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    
    _isLiked = widget.post['likes']?.contains(widget.currentUser?.uid) ?? false;
    _likeCount = widget.post['likes']?.length ?? 0;
  }

  @override
  void dispose() {
    _commentInputController.dispose();
    super.dispose();
  }

  Future<void> _editSharedPost(String postId, String currentContent) async {
    final String? updatedContent = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SharePostDialog(
          originalPostData: widget.post,
          initialContent: currentContent,
        );
      },
    );

    if (updatedContent != null) {
      try {
        await FirebaseFirestore.instance
            .collection('artifacts/${widget.appId}/public/data/posts')
            .doc(postId)
            .update({'content': updatedContent});
        widget.onMessage('Post updated successfully!');
      } on FirebaseException catch (e) {
        widget.onMessage('Failed to update post: ${e.message}');
      }
    }
  }

  Future<void> _deleteSharedPost(String postId, String originalPostId) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Shared Post'),
          content: const Text('Are you sure you want to delete this shared post? The original post will not be affected.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirmDelete) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final sharedPostRef = firestore.collection('artifacts/${widget.appId}/public/data/posts').doc(postId);
      final originalPostRef = firestore.collection('artifacts/${widget.appId}/public/data/posts').doc(originalPostId);

      await firestore.runTransaction((transaction) async {
        transaction.delete(sharedPostRef);
        transaction.update(originalPostRef, {'shares': FieldValue.increment(-1)});
      });

      widget.onMessage('Shared post deleted successfully!');
    } on FirebaseException catch (e) {
      widget.onMessage('Failed to delete shared post: ${e.message}');
    }
  }

  // <editor-fold desc="All other methods like _toggleLike, _addComment, etc. remain the same">
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

  Future<void> _toggleLike() async {
    final user = widget.currentUser;
    if (user == null || user.isAnonymous) {
      widget.onMessage('Please log in to like posts.');
      return;
    }

    final bool newIsLiked = !_isLiked;
    final int newLikeCount = newIsLiked ? _likeCount + 1 : _likeCount - 1;

    setState(() {
      _isLiked = newIsLiked;
      _likeCount = newLikeCount;
    });

    final postRef = FirebaseFirestore.instance
        .collection('artifacts/${widget.appId}/public/data/posts')
        .doc(widget.postId);
    
    try {
      if (newIsLiked) {
        await postRef.update({'likes': FieldValue.arrayUnion([user.uid])});
        
        if (widget.post['authorId'] != user.uid) {
          final currentUserDoc = await FirebaseFirestore.instance.collection('artifacts/${widget.appId}/public/data/users').doc(user.uid).get();
          final String currentUserName = currentUserDoc.data()?['displayName'] ?? 'Someone';
          
          await FirebaseFirestore.instance
              .collection('artifacts/${widget.appId}/public/data/users')
              .doc(widget.post['authorId'])
              .collection('notifications')
              .add({
                'type': 'like',
                'fromUserId': user.uid,
                'fromUserName': currentUserName,
                'postId': widget.postId,
                'content': 'liked your post.',
                'isRead': false,
                'timestamp': FieldValue.serverTimestamp(),
              });
        }
      } else {
        await postRef.update({'likes': FieldValue.arrayRemove([user.uid])});
      }
    } on FirebaseException catch (e) {
      setState(() {
        _isLiked = !newIsLiked;
        _likeCount = _isLiked ? newLikeCount + 1 : newLikeCount - 1;
      });
      widget.onMessage('Failed to update like status: ${e.message}');
    }
  }

  Future<void> _addComment(String postId, String commentText) async {
    if (commentText.trim().isEmpty) {
      widget.onMessage('Comment cannot be empty.');
      return;
    }
    final user = widget.currentUser;
    if (user == null || user.isAnonymous) {
      widget.onMessage('Please log in to comment.');
      return;
    }

    String commentAuthorDisplayName = user.email?.split('@')[0] ?? 'Anonymous';
    String commentAuthorProfileImageUrl = '';
    try {
      final userDoc = await FirebaseFirestore.instance.collection('artifacts/${widget.appId}/public/data/users').doc(user.uid).get();
      if (userDoc.exists) {
        commentAuthorDisplayName = userDoc.data()?['displayName'] ?? commentAuthorDisplayName;
        commentAuthorProfileImageUrl = userDoc.data()?['profileImageUrl'] ?? '';
      }
    } catch (e) {
      debugPrint('Error fetching comment author display name/image: $e');
    }

    final commentsCollectionRef = FirebaseFirestore.instance
        .collection('artifacts/${widget.appId}/public/data/posts')
        .doc(postId)
        .collection('comments');

    try {
      await commentsCollectionRef.add({
        'authorId': user.uid,
        'authorDisplayName': commentAuthorDisplayName,
        'authorProfileImageUrl': commentAuthorProfileImageUrl,
        'content': commentText.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      widget.onMessage('Comment added!');
      _commentInputController.clear();
      _updateEngagementScore(postId);

      if (widget.post['authorId'] != user.uid) {
        await FirebaseFirestore.instance
            .collection('artifacts/${widget.appId}/public/data/users')
            .doc(widget.post['authorId'])
            .collection('notifications')
            .add({
              'type': 'comment',
              'fromUserId': user.uid,
              'fromUserName': commentAuthorDisplayName,
              'postId': postId,
              'content': 'commented on your post: "${commentText.trim()}"',
              'isRead': false,
              'timestamp': FieldValue.serverTimestamp(),
            });
      }

    } on FirebaseException catch (e) {
      widget.onMessage('Failed to add comment: ${e.message}');
    } catch (e) {
      widget.onMessage('An unexpected error occurred: $e');
    }
  }

  Future<void> _sharePost(String postId) async {
    final user = widget.currentUser;
    if (user == null || user.isAnonymous) {
      widget.onMessage('Please log in to share posts.');
      return;
    }

    try {
      final originalPostDoc = await FirebaseFirestore.instance
          .collection('artifacts/${widget.appId}/public/data/posts')
          .doc(postId)
          .get();

      if (!originalPostDoc.exists) {
        widget.onMessage('Original post not found for sharing.');
        return;
      }
      final originalPostData = originalPostDoc.data()!;
      final originalPostAuthorId = originalPostData['authorId'];

      final sharerDoc = await FirebaseFirestore.instance
          .collection('artifacts/${widget.appId}/public/data/users')
          .doc(user.uid)
          .get();
      final sharerDisplayName = sharerDoc.data()?['displayName'] ?? 'Anonymous';
      final sharerProfileImageUrl = sharerDoc.data()?['profileImageUrl'] ?? '';

      final String? sharedContent = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return SharePostDialog(originalPostData: originalPostData);
        },
      );

      if (sharedContent == null) {
        return; 
      }

      await FirebaseFirestore.instance
          .collection('artifacts/${widget.appId}/public/data/posts')
          .add({
        'type': 'shared',
        'originalPostId': postId,
        'content': sharedContent.isNotEmpty ? sharedContent : null,
        'originalPostContent': originalPostData['content'],
        'originalPostMediaUrl': originalPostData['mediaUrl'],
        'originalPostMediaType': originalPostData['mediaType'],
        'originalPostAuthorId': originalPostAuthorId,
        'originalPostAuthorDisplayName': originalPostData['authorDisplayName'],
        'originalPostAuthorProfileImageUrl': originalPostData['authorProfileImageUrl'],
        'authorId': user.uid,
        'authorDisplayName': sharerDisplayName,
        'authorProfileImageUrl': sharerProfileImageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'shares': 0,
        'calculatedEngagement': _calculateEngagement(0, 0, 0),
        'postVisibility': 'everyone',
      });

      await FirebaseFirestore.instance
          .collection('artifacts/${widget.appId}/public/data/posts')
          .doc(postId)
          .update({
        'shares': FieldValue.increment(1),
      });

      if (originalPostAuthorId != user.uid) {
        await FirebaseFirestore.instance
            .collection('artifacts/${widget.appId}/public/data/users')
            .doc(originalPostAuthorId)
            .collection('notifications')
            .add({
              'type': 'share',
              'fromUserId': user.uid,
              'fromUserName': sharerDisplayName,
              'postId': postId,
              'content': 'shared your post.',
              'isRead': false,
              'timestamp': FieldValue.serverTimestamp(),
            });
      }

      widget.onMessage('Post shared successfully!');
      _updateEngagementScore(postId);

    } on FirebaseException catch (e) {
      widget.onMessage('Failed to share post: ${e.message}');
    } catch (e) {
      widget.onMessage('An unexpected error occurred: $e');
    }
  }

  Future<void> _deletePost(String postId, String? mediaUrl) async {
    final user = widget.currentUser;
    if (user == null || user.isAnonymous || user.uid != widget.post['authorId']) {
      widget.onMessage('You can only delete your own posts.');
      return;
    }

    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirmDelete) return;

    try {
      if (mediaUrl != null && mediaUrl.isNotEmpty) {
        final storageRef = FirebaseStorage.instance.refFromURL(mediaUrl);
        await storageRef.delete();
        widget.onMessage('Post media deleted from storage.');
      }

      final commentsSnapshot = await FirebaseFirestore.instance
          .collection('artifacts/${widget.appId}/public/data/posts')
          .doc(postId)
          .collection('comments')
          .get();
      for (final doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }

      await FirebaseFirestore.instance
          .collection('artifacts/${widget.appId}/public/data/posts')
          .doc(postId)
          .delete();

      widget.onMessage('Post deleted successfully!');
    } on FirebaseException catch (e) {
      widget.onMessage('Failed to delete post: ${e.message}');
    } catch (e) {
      widget.onMessage('An unexpected error occurred: $e');
    }
  }

  Future<void> _deleteComment(String postId, String commentId, String commentAuthorId) async {
    final user = widget.currentUser;
    if (user == null || user.isAnonymous) {
      widget.onMessage('You must be logged in to delete comments.');
      return;
    }

    final bool isCommentAuthor = user.uid == commentAuthorId;
    final bool isPostAuthor = user.uid == widget.post['authorId'];

    if (!isCommentAuthor && !isPostAuthor) {
      widget.onMessage('You can only delete your own comments or comments on your posts.');
      return;
    }

    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Comment'),
          content: const Text('Are you sure you want to delete this comment?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirmDelete) return;

    try {
      await FirebaseFirestore.instance
          .collection('artifacts/${widget.appId}/public/data/posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();
      widget.onMessage('Comment deleted!');
      _updateEngagementScore(postId);
    } on FirebaseException catch (e) {
        widget.onMessage('Failed to delete comment: ${e.message}');
    } catch (e) {
      widget.onMessage('An unexpected error occurred: $e');
    }
  }

  Future<void> _editComment(String postId, String commentId, String currentContent) async {
    final user = widget.currentUser;
    if (user == null || user.isAnonymous) {
      widget.onMessage('You must be logged in to edit comments.');
      return;
    }

    final commentDoc = await FirebaseFirestore.instance
        .collection('artifacts/${widget.appId}/public/data/posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .get();

    if (!commentDoc.exists || commentDoc.data()?['authorId'] != user.uid) {
      widget.onMessage('You can only edit your own comments.');
      return;
    }

    final TextEditingController editController = TextEditingController(text: currentContent);

    bool confirmEdit = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Comment'),
          content: TextField(
            controller: editController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Edit your comment'),
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                if (editController.text.trim().isEmpty) {
                  widget.onMessage('Comment cannot be empty.');
                  return;
                }
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmEdit) {
      try {
        await FirebaseFirestore.instance
            .collection('artifacts/${widget.appId}/public/data/posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .update({
          'content': editController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });
        widget.onMessage('Comment updated!');
      } on FirebaseException catch (e) {
        widget.onMessage('Failed to edit comment: ${e.message}');
      } catch (e) {
        widget.onMessage('An unexpected error occurred: $e');
      }
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final DateTime date = timestamp.toDate();
    // Use a relative format for timestamps. This helper returns strings like
    // "Just now", "5 mins ago", "Yesterday", or a short date depending on
    // how long ago the event occurred.
    return DateUtilsHelper.formatRelative(date);
  }
  //</editor-fold>

  /// Builds a thumbnail for a single media attachment.  Tapping the thumbnail
  /// opens a full‑screen [MediaViewer] with all attachments for this post.
  Widget _buildAttachmentThumbnail(List<dynamic> attachments) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    final Map<String, dynamic> first = attachments.first as Map<String, dynamic>;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String type = first['type'] ?? 'image';
    final String url = first['url'] ?? '';
    final double? aspectRatio = first['aspectRatio'] as double?;
    final bool allowAutoplay = !widget.isDataSaverOn || !widget.isOnMobileData;
    Widget thumb;
    switch (type) {
      case 'image':
        thumb = ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: CachedNetworkImage(
            imageUrl: url,
            placeholder: (context, url) => AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: scheme.surfaceVariant,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              color: scheme.surfaceVariant,
              child: Center(child: Icon(Icons.broken_image, color: scheme.onSurface, size: 50)),
            ),
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
        break;
      case 'video':
        if (allowAutoplay) {
          thumb = ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: VideoPlayerWidget(
              videoUrl: url,
              videoId: widget.postId,
              aspectRatio: aspectRatio,
              areControlsVisible: false,
              shouldInitialize: _isPostVisible,
            ),
          );
        } else {
          thumb = ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: AspectRatio(
              aspectRatio: aspectRatio ?? 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Thumbnail placeholder for video.  Currently we just show a dark
                  // container with a play icon overlay.  In the future, we can
                  // generate actual video thumbnails during upload.
                  Container(color: scheme.onSurface.withOpacity(0.54)),
                  Center(
                    child: Icon(Icons.play_circle_fill, color: scheme.onSurface.withOpacity(0.7), size: 56),
                  ),
                ],
              ),
            ),
          );
        }
        break;
      default:
        thumb = const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MediaViewer(
              mediaList: attachments.cast<Map<String, dynamic>>(),
              initialIndex: 0,
            ),
          ),
        );
      },
      child: Stack(
        children: [
          thumb,
          if (attachments.length > 1)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.onSurface.withOpacity(0.54),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${attachments.length - 1}',
                  style: TextStyle(color: scheme.onSurface, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showLikesDialog(BuildContext context, List<dynamic> likerIds) {
    if (likerIds.isEmpty) {
      widget.onMessage('No likes yet!');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Likes'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: likerIds.length,
              itemBuilder: (context, index) {
                final likerId = likerIds[index];
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('artifacts/${widget.appId}/public/data/users').doc(likerId).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(title: Text('Loading...'));
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const ListTile(title: Text('Unknown User'));
                    }
                    final userData = snapshot.data!.data() as Map<String, dynamic>;
                    final String displayName = userData['displayName'] ?? 'Unknown User';
                    final String profileImageUrl = userData['profileImageUrl'] ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: profileImageUrl.isNotEmpty
                            ? CachedNetworkImageProvider(profileImageUrl)
                            : null,
                        child: profileImageUrl.isEmpty
                            ? Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface)
                            : null,
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      ),
                      title: Text(displayName),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(userId: likerId),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMyPost = widget.currentUser?.uid == widget.post['authorId'];
    final int sharesCount = widget.post['shares'] ?? 0;

    final String authorDisplayName = widget.post['authorDisplayName'] ?? widget.post['authorEmail']?.split('@')[0] ?? 'Anonymous';
    final String authorProfileImageUrl = widget.post['authorProfileImageUrl'] ?? '';
    final String mediaType = widget.post['mediaType'] ?? 'text';
    final String postType = widget.post['type'] ?? 'original';

    final String originalPostContent = widget.post['originalPostContent'] ?? '';
    final String originalPostMediaUrl = widget.post['originalPostMediaUrl'] ?? '';
    final String originalPostMediaType = widget.post['originalPostMediaType'] ?? 'text';
    final String originalPostAuthorDisplayName = widget.post['originalPostAuthorDisplayName'] ?? 'Original Author';
    
    final double? aspectRatio = widget.post['aspectRatio'] as double?;
    final List<dynamic> attachments = (widget.post['media'] ?? []) as List<dynamic>;

    return VisibilityDetector(
      key: Key(widget.postId),
      onVisibilityChanged: (info) {
        if (!mounted) return;
        final isVisible = info.visibleFraction > 0.1;
        if (isVisible != _isPostVisible) {
          setState(() {
            _isPostVisible = isVisible;
          });
        }
      },
      child: FoutaCard(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              if (postType == 'shared')
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.repeat, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Shared by $authorDisplayName',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(userId: widget.post['authorId']),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: authorProfileImageUrl.isNotEmpty
                          ? CachedNetworkImageProvider(authorProfileImageUrl)
                          : null,
                      child: authorProfileImageUrl.isEmpty
                          ? Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface)
                          : null,
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(userId: widget.post['authorId']),
                        ),
                      );
                    },
                    child: Text(
                      authorDisplayName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTimestamp(widget.post['timestamp'] as Timestamp?),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                  ),
                  if (isMyPost)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (postType == 'shared') {
                          if (value == 'edit_shared') {
                            _editSharedPost(widget.postId, widget.post['content'] ?? '');
                          } else if (value == 'delete_shared') {
                            _deleteSharedPost(widget.postId, widget.post['originalPostId']);
                          }
                        } else {
                           if (value == 'edit_original') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreatePostScreen(
                                  postId: widget.postId,
                                  initialContent: widget.post['content'],
                                  initialMediaUrl: widget.post['mediaUrl'],
                                  initialMediaType: widget.post['mediaType'],
                                ),
                              ),
                            );
                          } else if (value == 'delete_original') {
                            _deletePost(widget.postId, widget.post['mediaUrl']);
                          }
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        if (postType == 'shared') {
                          return <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit_shared',
                              child: Text('Edit Shared Post'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete_shared',
                              child: Text('Delete Shared Post'),
                            ),
                          ];
                        } else {
                          return <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit_original',
                              child: Text('Edit Post'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete_original',
                              child: Text('Delete Post'),
                            ),
                          ];
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (postType == 'shared' && widget.post['content'] != null && widget.post['content'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    widget.post['content'],
                    style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ),
              if (postType == 'shared')
                Container(
                  margin: const EdgeInsets.only(top: 8.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Original post by $originalPostAuthorDisplayName',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (originalPostMediaUrl.isNotEmpty)
                        _buildAttachmentThumbnail([
                          {
                            'type': originalPostMediaType,
                            'url': originalPostMediaUrl,
                          }
                        ]),
                      if (originalPostMediaUrl.isNotEmpty) const SizedBox(height: 8),
                      if (originalPostContent.isNotEmpty)
                        Text(
                          originalPostContent,
                          style: const TextStyle(fontSize: 15),
                        ),
                    ],
                  ),
                )
              else if (widget.post['content'] != null && widget.post['content'].isNotEmpty)
                Text(
                  widget.post['content'],
                  style: const TextStyle(fontSize: 16),
                ),
              // Display attachments if present.  Fall back to legacy single media for
              // backwards compatibility.
              if (postType == 'original' && attachments.isNotEmpty)
                _buildAttachmentThumbnail(attachments),
              if (postType == 'original' && attachments.isNotEmpty) const SizedBox(height: 12),
              if (postType == 'original' && attachments.isEmpty && widget.post['mediaUrl'] != null && widget.post['mediaUrl'].isNotEmpty)
                _buildAttachmentThumbnail([
                  {
                    'type': mediaType,
                    'url': widget.post['mediaUrl'],
                    'aspectRatio': aspectRatio,
                  }
                ]),
              if (postType == 'original' && attachments.isEmpty && widget.post['mediaUrl'] != null && widget.post['mediaUrl'].isNotEmpty)
                const SizedBox(height: 12),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: _toggleLike,
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _showLikesDialog(context, widget.post['likes'] ?? []),
                          child: Text(
                            '$_likeCount',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showComments = !_showComments;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.comment, color: Theme.of(context).iconTheme.color),
                          const SizedBox(width: 4),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('artifacts/${widget.appId}/public/data/posts')
                                .doc(widget.postId)
                                .collection('comments')
                                .snapshots(),
                            builder: (context, commentSnapshot) {
                              if (commentSnapshot.connectionState == ConnectionState.waiting) {
                                return const Text('...');
                              }
                              final int commentCount = commentSnapshot.data?.docs.length ?? 0;
                              return Text(
                                '$commentCount',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _sharePost(widget.postId),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share, color: Theme.of(context).iconTheme.color),
                          const SizedBox(width: 4),
                          Text(
                            '$sharesCount',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_showComments) ...[
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('artifacts/${widget.appId}/public/data/posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, commentSnapshot) {
                    if (commentSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final comments = commentSnapshot.data?.docs ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...comments.map((commentDoc) {
                          final comment = commentDoc.data() as Map<String, dynamic>;
                          final String commentAuthorDisplayName = comment['authorDisplayName'] ?? 'Anonymous';
                          final String commentAuthorProfileImageUrl = comment['authorProfileImageUrl'] ?? '';
                          final String commentAuthorId = comment['authorId'];
                          final String commentId = commentDoc.id;

                          final ColorScheme scheme = Theme.of(context).colorScheme;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: scheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundImage: commentAuthorProfileImageUrl.isNotEmpty
                                        ? CachedNetworkImageProvider(commentAuthorProfileImageUrl)
                                        : null,
                                    child: commentAuthorProfileImageUrl.isEmpty
                                        ? Icon(Icons.person, size: 12, color: scheme.onSurface)
                                        : null,
                                    backgroundColor: scheme.surfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          comment['content'],
                                          style: TextStyle(color: scheme.onSurface, fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$commentAuthorDisplayName - ${_formatTimestamp(comment['timestamp'] as Timestamp?)}',
                                          style: TextStyle(
                                              color: scheme.onSurface.withOpacity(0.6), fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (widget.currentUser?.uid == commentAuthorId || widget.currentUser?.uid == widget.post['authorId'])
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _editComment(widget.postId, commentId, comment['content']);
                                        } else if (value == 'delete') {
                                          _deleteComment(widget.postId, commentId, commentAuthorId);
                                        }
                                      },
                                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                        if (widget.currentUser?.uid == commentAuthorId)
                                          const PopupMenuItem<String>(
                                            value: 'edit',
                                            child: Text('Edit Comment'),
                                          ),
                                        const PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Text('Delete Comment'),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _commentInputController,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            suffixIcon: IconButton(
                              icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                              onPressed: () {
                                _addComment(widget.postId, _commentInputController.text);
                              },
                            ),
                          ),
                          onSubmitted: (value) {
                            _addComment(widget.postId, value);
                          },
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
    );
  }
}
