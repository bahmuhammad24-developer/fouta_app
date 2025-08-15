// lib/widgets/post_card_widget.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fouta_app/widgets/video_player_widget.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:fouta_app/utils/date_utils.dart';

import 'package:fouta_app/widgets/animated_like_button.dart';
import 'package:fouta_app/widgets/animated_bookmark_button.dart';
import 'package:fouta_app/widgets/progressive_image.dart';
import 'package:fouta_app/widgets/reaction_tray.dart';
import 'package:fouta_app/widgets/skeleton.dart';
import 'package:fouta_app/utils/haptics.dart';


import 'package:fouta_app/main.dart'; // Import APP_ID
import 'package:fouta_app/screens/create_post_screen.dart';
import 'package:fouta_app/screens/profile_screen.dart';
// Use the unified FullScreenMediaViewer instead of separate full screen image/video widgets
import '../models/media_item.dart';
import 'media/post_media.dart';
import 'package:fouta_app/widgets/share_post_dialog.dart';
import 'package:fouta_app/widgets/fouta_card.dart';
import 'package:fouta_app/utils/overlays.dart';
import 'package:fouta_app/widgets/fouta_button.dart';
import 'package:fouta_app/features/moderation/moderation_service.dart';
import 'package:fouta_app/utils/json_safety.dart';
import '../services/post_service.dart';
import 'package:fouta_app/theme/tokens.dart';
import '../services/collections_service.dart';
import '../features/stories/composer/create_story_screen.dart';
import '../features/creation/editor/overlays/overlay_models.dart';
import 'package:fouta_app/navigation/transitions.dart';
import 'package:fouta_app/screens/post_detail_screen.dart';
import 'package:fouta_app/widgets/progressive_image.dart';

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
  late bool _isBookmarked;
  late int _bookmarkCount;

  @override
  void initState() {
    super.initState();
    final likes = asStringList(widget.post['likes']);
    _isLiked = likes.contains(widget.currentUser?.uid);
    _likeCount = likes.length;
    final bookmarks = asStringList(widget.post['bookmarks']);
    _isBookmarked = bookmarks.contains(widget.currentUser?.uid);
    _bookmarkCount = bookmarks.length;
  }

  @override
  void dispose() {
    _commentInputController.dispose();
    super.dispose();
  }

  Future<void> _editQuotePost(String postId, String currentContent) async {
    final String? updatedContent = await showFoutaDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SharePostDialog(
          originalPostData: {
            'content': widget.post['originContent'],
            'mediaUrl': widget.post['originMediaUrl'],
            'mediaType': widget.post['originMediaType'],
            'authorDisplayName': widget.post['originAuthorDisplayName'],
          },
          initialContent: currentContent,
        );
      },
    );

    if (updatedContent != null) {
      try {
        await FirebaseFirestore.instance
            .collection('artifacts/${widget.appId}/public/data/posts')
            .doc(postId)
            .update({'quoteText': updatedContent});
        widget.onMessage('Post updated successfully!');
      } on FirebaseException catch (e) {
        widget.onMessage('Failed to update post: ${e.message}');
      }
    }
  }

  Future<void> _deleteQuotePost(String postId, String originPostId) async {
    bool confirmDelete = await showFoutaDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Quote Post'),
          content: const Text('Are you sure you want to delete this quote post? The original post will not be affected.'),
          actions: <Widget>[
            FoutaButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(false),
              primary: false,
            ),
            FoutaButton(
              label: 'Delete',
              onPressed: () => Navigator.of(context).pop(true),
              primary: true,
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirmDelete) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final sharedPostRef = firestore.collection('artifacts/${widget.appId}/public/data/posts').doc(postId);
      final originalPostRef = firestore.collection('artifacts/${widget.appId}/public/data/posts').doc(originPostId);

      await firestore.runTransaction((transaction) async {
        transaction.delete(sharedPostRef);
        transaction.update(originalPostRef, {'shares': FieldValue.increment(-1)});
      });

      widget.onMessage('Shared post deleted successfully!');
    } on FirebaseException catch (e) {
      widget.onMessage('Failed to delete quote post: ${e.message}');
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
        final int likes = asStringList(data['likes']).length;
        final commentsSnapshot = await postRef.collection('comments').get();
        final int comments = commentsSnapshot.docs.length;
        final int shares = asInt(data['shares']);

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

    Haptics.light();

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

  void _likeOnDoubleTap() {
    if (!_isLiked) {
      _toggleLike();
    }
  }

  Future<void> _toggleBookmark() async {
    final user = widget.currentUser;
    if (user == null || user.isAnonymous) {
      widget.onMessage('Please log in to bookmark posts.');
      return;
    }

    Haptics.light();

    final bool newIsBookmarked = !_isBookmarked;
    final int newBookmarkCount =
        newIsBookmarked ? _bookmarkCount + 1 : _bookmarkCount - 1;

    setState(() {
      _isBookmarked = newIsBookmarked;
      _bookmarkCount = newBookmarkCount;
    });

    final postRef = FirebaseFirestore.instance
        .collection('artifacts/${widget.appId}/public/data/posts')
        .doc(widget.postId);

    try {
      if (newIsBookmarked) {
        await postRef
            .update({'bookmarks': FieldValue.arrayUnion([user.uid])});
      } else {
        await postRef
            .update({'bookmarks': FieldValue.arrayRemove([user.uid])});
      }
    } on FirebaseException catch (e) {
      setState(() {
        _isBookmarked = !newIsBookmarked;
        _bookmarkCount = _isBookmarked
            ? newBookmarkCount + 1
            : newBookmarkCount - 1;
      });
      widget.onMessage('Failed to update bookmark: ${e.message}');
    }
  }

  void _openReactionTray() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ReactionTray(
        onReactionSelected: (type) {
          Navigator.pop(context);
          widget.onMessage('Reacted: ${type.name}');
        },
      ),
    );
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

  Future<void> _quotePost(String postId) async {
    final user = widget.currentUser;
    if (user == null || user.isAnonymous) {
      widget.onMessage('Please log in to share posts.');
      return;
    }
    final originalPostDoc = await FirebaseFirestore.instance
        .collection('artifacts/${widget.appId}/public/data/posts')
        .doc(postId)
        .get();
    if (!originalPostDoc.exists) {
      widget.onMessage('Original post not found for sharing.');
      return;
    }
    final originalPostData = originalPostDoc.data()!;
    final String? sharedContent = await showFoutaDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SharePostDialog(originalPostData: originalPostData);
      },
    );
    if (sharedContent == null) return;
    await PostService().quotePost(postId, sharedContent);
    widget.onMessage('Post shared successfully!');
    _updateEngagementScore(postId);
  }

  Future<void> _repost(String postId) async {
    final user = widget.currentUser;
    if (user == null || user.isAnonymous) {
      widget.onMessage('Please log in to share posts.');
      return;
    }
    await PostService().repost(postId);
    widget.onMessage('Post shared successfully!');
    _updateEngagementScore(postId);
  }

  Future<void> _saveToCollection() async {
    final uid = widget.currentUser?.uid;
    if (uid == null) {
      widget.onMessage('Please log in to save posts.');
      return;
    }
    final service = CollectionsService();
    final collectionId = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.streamCollections(uid),
          builder: (ctx, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            return ListView(
              children: [
                for (final d in docs)
                  ListTile(
                    title: Text(d['name']?.toString() ?? 'Unnamed'),
                    onTap: () => Navigator.pop(ctx, d.id),
                  ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('New collection'),
                  onTap: () async {
                    final controller = TextEditingController();
                    final name = await showDialog<String>(
                      context: ctx,
                      builder: (c) => AlertDialog(
                        title: const Text('Collection name'),
                        content: TextField(controller: controller, autofocus: true),
                        actions: [
                          FoutaButton(
                            label: 'Cancel',
                            onPressed: () => Navigator.pop(c),
                            primary: false,
                          ),
                          FoutaButton(
                            label: 'Create',
                            onPressed: () =>
                                Navigator.pop(c, controller.text.trim()),
                            primary: true,
                          ),
                        ],
                      ),
                    );
                    if (name != null && name.isNotEmpty) {
                      final id = await service.createCollection(uid, name);
                      Navigator.pop(ctx, id);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
    if (collectionId != null) {
      await service.addToCollection(uid, collectionId, widget.postId);
      widget.onMessage('Saved to collection');
    }
  }

  Future<void> _shareToStory() async {
    final uid = widget.currentUser?.uid;
    if (uid == null) {
      widget.onMessage('Please log in to share posts.');
      return;
    }
    final mediaUrl = widget.post['mediaUrl'];
    final mediaType = widget.post['mediaType'];
    final authorName = widget.post['authorDisplayName'] ?? 'user';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateStoryScreen(
          initialImageUrl: mediaType == 'image' ? mediaUrl : null,
          initialVideoUrl: mediaType == 'video' ? mediaUrl : null,
          initialOverlays: [
            TextOverlay(
              id: 'shared',
              text: 'Shared from @$authorName',
              color: Colors.white.value,
              fontSize: 24,
              dx: 20,
              dy: 20,
              scale: 1,
              rotation: 0,
              opacity: 1,
              z: 0,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reportPost(String postId, String authorId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      widget.onMessage('Please log in to report posts.');
      return;
    }
    final TextEditingController reasonController = TextEditingController();
    final String? reason = await showFoutaDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report Post'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(labelText: 'Reason'),
            maxLines: 3,
          ),
          actions: [
            FoutaButton(
              label: 'Cancel',
              onPressed: () => Navigator.pop(context),
              primary: false,
            ),
            FoutaButton(
              label: 'Submit',
              onPressed: () => Navigator.pop(context, reasonController.text.trim()),
              primary: true,
            ),
          ],
        );
      },
    );
    if (reason == null || reason.isEmpty) return;
    try {
      await ModerationService(appId: widget.appId).reportPost(
        postId: postId,
        reporterId: user.uid,
        authorId: authorId,
        reason: reason,
      );
      widget.onMessage('Report submitted');
    } catch (e) {
      widget.onMessage('Failed to submit report: $e');
    }
  }

  Future<void> _deletePost(String postId, String? mediaUrl) async {
    final user = widget.currentUser;
    if (user == null || user.isAnonymous || user.uid != widget.post['authorId']) {
      widget.onMessage('You can only delete your own posts.');
      return;
    }

    bool confirmDelete = await showFoutaDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: <Widget>[
            FoutaButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(false),
              primary: false,
            ),
            FoutaButton(
              label: 'Delete',
              onPressed: () => Navigator.of(context).pop(true),
              primary: true,
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

    bool confirmDelete = await showFoutaDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Comment'),
          content: const Text('Are you sure you want to delete this comment?'),
          actions: <Widget>[
            FoutaButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(false),
              primary: false,
            ),
            FoutaButton(
              label: 'Delete',
              onPressed: () => Navigator.of(context).pop(true),
              primary: true,
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

    bool confirmEdit = await showFoutaDialog<bool>(
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
            FoutaButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(false),
              primary: false,
            ),
            FoutaButton(
              label: 'Save',
              onPressed: () {
                if (editController.text.trim().isEmpty) {
                  widget.onMessage('Comment cannot be empty.');
                  return;
                }
                Navigator.of(context).pop(true);
              },
              primary: true,
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
  /// opens the post detail screen with a hero transition.
  Widget _buildAttachmentThumbnail(List<dynamic> attachments) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    final Map<String, dynamic> first = attachments.first as Map<String, dynamic>;
    final String type = first['type'] ?? 'image';
    final String url = first['url'] ?? '';
    final double? aspectRatio = first['aspectRatio'] as double?;
    final bool allowAutoplay = !widget.isDataSaverOn || !widget.isOnMobileData;
    Widget thumb;
    switch (type) {
      case 'image':

        thumb = ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Stack(
            fit: StackFit.expand,
              children: [
            Skeleton.rect(),
              ProgressiveImage(
                imageUrl: url,
                thumbUrl: first['thumbUrl'] ?? url,
                fit: BoxFit.cover,
              ),
            ],
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
          final poster = first['thumbUrl'] ?? first['url'];
          thumb = ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: AspectRatio(
              aspectRatio: aspectRatio ?? 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                  children: [
                  Skeleton.rect(),
                  ProgressiveImage(
                    imageUrl: poster,
                    thumbUrl: poster,
                    fit: BoxFit.cover,
                  ),
                  Container(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.54)),
                  Center(
                    child: Icon(Icons.play_circle_fill,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withOpacity(0.70),
                        size: 56),
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
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          FoutaTransitions.pushFromRight(
            PostDetailScreen(postId: widget.postId),
          ),
        );
      },
      onDoubleTap: _likeOnDoubleTap,
      focusColor: AppColors.primary.withOpacity(0.3),
      child: Stack(
        children: [
          Hero(tag: '${widget.postId}-media', child: thumb),
          if (attachments.length > 1)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.54),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${attachments.length - 1}',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showLikesDialog(BuildContext context, List<String> likerIds) {
    if (likerIds.isEmpty) {
      widget.onMessage('No likes yet!');
      return;
    }

    showFoutaDialog(
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

                            ? Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimary)

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
            FoutaButton(
              label: 'Close',
              onPressed: () {
                Navigator.of(context).pop();
              },
              primary: false,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMyPost = widget.currentUser?.uid == widget.post['authorId'];
    final int sharesCount = asInt(widget.post['shares']);

    final String authorDisplayName = widget.post['authorDisplayName'] ?? widget.post['authorEmail']?.split('@')[0] ?? 'Anonymous';
    final String authorProfileImageUrl = widget.post['authorProfileImageUrl'] ?? '';
    final String mediaType = widget.post['mediaType'] ?? 'text';
    final String postType = widget.post['type'] ?? 'original';

    final String originContent = widget.post['originContent'] ?? '';
    final String originMediaUrl = widget.post['originMediaUrl'] ?? '';
    final String originMediaType = widget.post['originMediaType'] ?? 'text';
    final String originAuthorDisplayName = widget.post['originAuthorDisplayName'] ?? 'Original Author';

    final double? aspectRatio = widget.post['aspectRatio'] as double?;
    final List<dynamic> attachments = (widget.post['media'] ?? []) as List<dynamic>;
    final double textScale = MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.3);

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
              if (postType == 'repost' || postType == 'quote')
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [

                      Icon(Icons.repeat, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),

                      const SizedBox(width: 4),
                      Text(
                        'Shared by $authorDisplayName',
                        style: TextStyle(

                          color: Theme.of(context).colorScheme.onSurfaceVariant,

                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                        textScaleFactor: textScale,
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(userId: widget.post['authorId']),
                        ),
                      );
                    },
                    focusColor: AppColors.primary.withOpacity(0.3),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: authorProfileImageUrl.isNotEmpty
                          ? CachedNetworkImageProvider(authorProfileImageUrl)
                          : null,
                      child: authorProfileImageUrl.isEmpty

                          ? Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimary)

                          : null,
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(userId: widget.post['authorId']),
                        ),
                      );
                    },
                    focusColor: AppColors.primary.withOpacity(0.3),
                    child: Text(
                      authorDisplayName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textScaleFactor: textScale,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTimestamp(widget.post['timestamp'] as Timestamp?),

                    style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12),

                  ),
                  if (isMyPost)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (postType == 'quote') {
                          if (value == 'edit_shared') {
                            _editQuotePost(widget.postId, widget.post['quoteText'] ?? '');
                          } else if (value == 'delete_shared') {
                            _deleteQuotePost(widget.postId, widget.post['originPostId']);
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
                        if (postType == 'quote') {
                          return <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit_shared',
                              child: Text('Edit Quote'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete_shared',
                              child: Text('Delete Quote'),
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
                    )
                  else
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'report') {
                          _reportPost(
                              widget.postId, widget.post['authorId'] ?? '');
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return const <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'report',
                            child: Text('Report Post'),
                          ),
                        ];
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (postType == 'quote' && widget.post['quoteText'] != null && widget.post['quoteText'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    widget.post['quoteText'],
                    style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ),
              if (postType == 'repost' || postType == 'quote')
                Container(
                  margin: const EdgeInsets.only(top: 8.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12.0),

                    border: Border.all(color: Theme.of(context).colorScheme.surfaceVariant),

                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Original post by $originAuthorDisplayName',
                        style: TextStyle(
                          fontSize: 13,

                          color: Theme.of(context).colorScheme.outline,

                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (originMediaUrl.isNotEmpty)
                        _buildAttachmentThumbnail([
                          {
                            'type': originMediaType,
                            'url': originMediaUrl,
                          }
                        ]),
                      if (originMediaUrl.isNotEmpty) const SizedBox(height: 8),
                      if (originContent.isNotEmpty)
                        Text(
                          originContent,
                          style: const TextStyle(fontSize: 15),
                          textScaleFactor: textScale,
                          softWrap: true,
                        ),
                    ],
                  ),
                )
              else if (widget.post['content'] != null && widget.post['content'].isNotEmpty)
                Text(
                  widget.post['content'],
                  style: const TextStyle(fontSize: 16),
                  textScaleFactor: textScale,
                  softWrap: true,
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
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Semantics(
                          label: _isLiked ? 'Unlike post' : 'Like post',
                          button: true,
                          child: GestureDetector(
                            onLongPress: _openReactionTray,
                            child: AnimatedLikeButton(
                              isLiked: _isLiked,
                              onChanged: (v) => _toggleLike(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _showLikesDialog(context, asStringList(widget.post['likes'])),
                          focusColor: AppColors.primary.withOpacity(0.3),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.comment),
                          tooltip: 'Comments',
                          onPressed: () {
                            setState(() {
                              _showComments = !_showComments;
                            });
                          },
                          style: IconButton.styleFrom(
                            foregroundColor: Theme.of(context).iconTheme.color,
                          ),
                        ),
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
                  Expanded(
                    child: PopupMenuButton<String>(
                      tooltip: 'Share',
                      onSelected: (value) {
                        switch (value) {
                          case 'repost':
                            _repost(widget.postId);
                            break;
                          case 'quote':
                            _quotePost(widget.postId);
                            break;
                          case 'save':
                            _saveToCollection();
                            break;
                          case 'story':
                            _shareToStory();
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'repost', child: Text('Repost')),
                        PopupMenuItem(value: 'quote', child: Text('Quote')),
                        PopupMenuItem(value: 'save', child: Text('Save to Collection')),
                        PopupMenuItem(value: 'story', child: Text('Share to Story')),
                      ],
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
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                          ),
                          tooltip: _isBookmarked
                              ? 'Remove bookmark'
                              : 'Bookmark',
                          onPressed: _toggleBookmark,
                          style: IconButton.styleFrom(
                            foregroundColor: _isBookmarked
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).iconTheme.color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_bookmarkCount',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
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

                                color: Theme.of(context).colorScheme.outline,

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

                                        ? Icon(Icons.person, size: 12, color: Theme.of(context).colorScheme.onPrimary)
                                        : null,
                                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,

                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          comment['content'],

                                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),

                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$commentAuthorDisplayName - ${_formatTimestamp(comment['timestamp'] as Timestamp?)}',

                                            style: TextStyle(
                                                color: Theme.of(context).colorScheme.outline, fontSize: 10),

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
                              icon: Icon(Icons.send,
                                  color: Theme.of(context).colorScheme.primary),
                              tooltip: 'Send comment',
                              onPressed: () {
                                _addComment(widget.postId,
                                    _commentInputController.text);
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
