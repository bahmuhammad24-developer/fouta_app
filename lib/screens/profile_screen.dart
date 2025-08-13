// lib/screens/profile_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/screens/post_detail_screen.dart';
import 'package:fouta_app/services/media_service.dart';
import 'dart:io';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:fouta_app/main.dart'; // Import APP_ID
import 'package:fouta_app/screens/chat_screen.dart';
import 'package:fouta_app/screens/fullscreen_media_viewer.dart';
import 'package:fouta_app/models/media_item.dart';
import 'package:fouta_app/widgets/post_card_widget.dart';
import 'package:fouta_app/widgets/fouta_button.dart';
import 'package:fouta_app/screens/create_post_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fouta_app/utils/firestore_paths.dart';
import 'package:fouta_app/widgets/skeletons/profile_skeleton.dart';
import 'package:fouta_app/utils/snackbar.dart';
import 'package:fouta_app/widgets/skeletons/feed_skeleton.dart';
import 'package:fouta_app/utils/overlays.dart';
import 'package:fouta_app/features/profile/profile_service.dart';
import 'package:fouta_app/features/analytics/creator_insights.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final bool initialIsEditing;
  final FirebaseFirestore firestore;
  const ProfileScreen({
    super.key,
    required this.userId,
    this.initialIsEditing = false,
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

// Add SingleTickerProviderStateMixin for the TabController
class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final _bioController = TextEditingController();
  late bool _isEditing;
  String _currentProfileImageUrl = '';
  MediaAttachment? _newProfileImage;
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  final MediaService _mediaService = MediaService();

  late final ProfileService _profileService;
  late final CreatorInsights _insights;
  int _posts7d = 0;
  int _engagement7d = 0;
  String? _pinnedPostId;
  bool _isCreator = false;
  Map<String, dynamic>? _userData;

  bool _isDataSaverOn = true;
  bool _isOnMobileData = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // TAB CONTROLLER SETUP
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialIsEditing;
    _profileService = ProfileService(firestore: widget.firestore);
    _insights = CreatorInsights(firestore: widget.firestore);
    _tabController = TabController(length: 3, vsync: this);
    _loadDataSaverPreference();
    Connectivity().checkConnectivity().then((result) {
      if (mounted) {
        setState(() {
          _isOnMobileData = result is List<ConnectivityResult>
              ? result.contains(ConnectivityResult.mobile)
              : result == ConnectivityResult.mobile;
        });
      }
    });
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() {
          _isOnMobileData = results.contains(ConnectivityResult.mobile);
        });
      }
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _bioController.dispose();
    _tabController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _showMessage(String msg) {
    if (!mounted) return;

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

  Future<void> _loadDataSaverPreference() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final doc = await FirebaseFirestore.instance
          .collection(FirestorePaths.users())
          .doc(currentUser.uid)
          .get();
      if (mounted) {
        setState(() {
          _isDataSaverOn = doc.data()?['dataSaver'] ?? true;
        });
      }
    }
  }

  Future<void> _loadCreatorInsights(String uid) async {
    final posts = await _insights.countPostsLastNDays(uid, 7);
    final engagement = await _insights.sumEngagementLastNDays(uid, 7);
    if (mounted) {
      setState(() {
        _posts7d = posts;
        _engagement7d = engagement;
      });
    }
  }

  Widget _dashboardTile(BuildContext context, String label, int value) {
    return Column(
      children: [
        Text('$value',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(color: Theme.of(context).colorScheme.outline)),
      ],
    );
  }

  Future<void> _pickProfileImage() async {
    if (_isUploading) {
      _showMessage('Upload in progress. Please wait.');
      return;
    }

    final attachment = await _mediaService.pickImage();
    if (attachment == null) {
      _showMessage('No image selected.');
      return;
    }

    _showMessage('Image selected. Tap the checkmark to save changes.');
    setState(() {
      _newProfileImage = attachment;
    });
  }

  Future<void> _updateProfile(String currentProfileImageUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != widget.userId) {
      _showMessage('You can only edit your own profile.');
      return;
    }

    String? newImageUrl = currentProfileImageUrl;
    if (_newProfileImage != null) {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });
      try {
        final uploaded = await _mediaService.upload(
          _newProfileImage!,
          pathPrefix: 'profile_images/${user.uid}',
        );
        newImageUrl = uploaded.url;
        _showMessage('Profile image uploaded successfully!');
      } on FirebaseException catch (e) {
        _showMessage('Profile image upload failed: ${e.message}');
        if (mounted) setState(() => _isUploading = false);
        return;
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }

    try {
      await FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(user.uid).update({
        'bio': _bioController.text.trim(),
        'profileImageUrl': newImageUrl,
      });

      final userPostsQuery = FirebaseFirestore.instance
          .collection('artifacts/$APP_ID/public/data/posts')
          .where('authorId', isEqualTo: user.uid);

      final userPostsSnapshot = await userPostsQuery.get();
      for (final postDoc in userPostsSnapshot.docs) {
        await postDoc.reference.update({
          'authorProfileImageUrl': newImageUrl,
        });
      }

      _showMessage('Profile updated successfully!');
      if(mounted) {
        setState(() {
          _isEditing = false;
          _newProfileImage = null;
          _uploadProgress = 0.0;
        });
      }
    } on FirebaseException catch (e) {
      _showMessage('Failed to update profile: ${e.message}');
    }
  }

  Future<void> _toggleFollow(String currentUserId, String targetUserId, bool isCurrentlyFollowing) async {
    if (currentUserId == targetUserId) {
      _showMessage('You cannot follow yourself.');
      return;
    }
    try {
      final currentUserRef = FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(currentUserId);
      final targetUserRef = FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(targetUserId);
      final currentUserDoc = await currentUserRef.get();

      if (isCurrentlyFollowing) {
        await currentUserRef.update({'following': FieldValue.arrayRemove([targetUserId])});
        await targetUserRef.update({'followers': FieldValue.arrayRemove([currentUserId])});
        if(mounted) _showMessage('Unfollowed user.');
      } else {
        await currentUserRef.update({'following': FieldValue.arrayUnion([targetUserId])});
        await targetUserRef.update({'followers': FieldValue.arrayUnion([currentUserId])});
        
        final String currentUserName = currentUserDoc.data()?['displayName'] ?? 'Someone';
        await targetUserRef.collection('notifications').add({
          'type': 'follow',
          'fromUserId': currentUserId,
          'fromUserName': currentUserName,
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if(mounted) _showMessage('Followed user.');
      }
    } on FirebaseException catch (e) {
      _showMessage('Failed to update follow status: ${e.message}');
    }
  }

  void _showUserListDialog(BuildContext context, List<dynamic> userIds, String title) {
    if (userIds.isEmpty) {
      _showMessage('No $title yet!');
      return;
    }

    showFoutaDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: userIds.length,
              itemBuilder: (context, index) {
                final userId = userIds[index];
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(userId).get(),
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
                            builder: (context) => ProfileScreen(userId: userId),
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

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final DateTime date = timestamp.toDate();
    return DateFormat('MMM d, yyyy').format(date);
  }

  // WIDGET BUILDERS FOR UI SECTIONS
  Widget _buildProfileHeader(Map<String, dynamic> userData, bool isMyProfile, User? currentUser) {
    final String displayName = userData['displayName'] ?? 'No Name';
    final String bio = userData['bio'] ?? 'No bio yet.';
    final Timestamp? createdAt = userData['createdAt'] as Timestamp?;
    final List<dynamic> followers = userData['followers'] ?? [];
    final List<dynamic> following = userData['following'] ?? [];
    final bool isFollowing = (userData['followers'] ?? []).contains(currentUser?.uid);
    
    if (_isEditing) {
      _bioController.text = bio;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: isMyProfile ? () {
              if (_isEditing) {
                _pickProfileImage();
              } else if (_currentProfileImageUrl.isNotEmpty) {
                FullScreenMediaViewer.open(
                  context,
                  [
                    MediaItem(
                      id: 'profile-image',
                      type: MediaType.image,
                      url: _currentProfileImageUrl,
                    ),
                  ],
                  initialIndex: 0,
                );
              }
            } : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: (_newProfileImage != null && kIsWeb && _newProfileImage!.bytes != null)
                      ? MemoryImage(_newProfileImage!.bytes!)
                      : (_newProfileImage != null && !kIsWeb)
                          ? FileImage(File(_newProfileImage!.file.path)) as ImageProvider
                          : (_currentProfileImageUrl.isNotEmpty ? CachedNetworkImageProvider(_currentProfileImageUrl) : null),
                  child: (_currentProfileImageUrl.isEmpty && _newProfileImage == null)
                      ? Icon(Icons.person, size: 60, color: Theme.of(context).colorScheme.onPrimary)
                      : null,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                ),
                if (isMyProfile)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: IconButton(
                        icon: Icon(_isEditing ? Icons.check : Icons.edit, color: Theme.of(context).colorScheme.onPrimary),
                        onPressed: () {
                          if (_isEditing) {
                            _updateProfile(_currentProfileImageUrl);
                          } else {
                            setState(() {
                              _isEditing = true;
                            });
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: LinearProgressIndicator(value: _uploadProgress),
            ),
          const SizedBox(height: 16),
          Text(displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_isEditing)
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Bio'),
              textAlign: TextAlign.center,
            )
          else
            Text(bio, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.outline)),
          const SizedBox(height: 16),
          Text('Joined: ${_formatTimestamp(createdAt)}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _showUserListDialog(context, followers, 'Followers'),
                child: Column(
                  children: [
                    Text('${followers.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Followers', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                  ],
                ),
              ),
              const SizedBox(width: 30),
              GestureDetector(
                onTap: () => _showUserListDialog(context, following, 'Following'),
                child: Column(
                  children: [
                    Text('${following.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Following', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isCreator)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _dashboardTile(context, 'Followers', followers.length),
                  _dashboardTile(context, '7-day posts', _posts7d),
                  _dashboardTile(context, '7-day engagement', _engagement7d),
                ],
              ),
            ),
          if (isMyProfile)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton(
                onPressed: () {
                  if (_userData != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(
                          uid: widget.userId,
                          initialData: _userData!,
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Edit Profile'),
              ),
            ),
          if (!isMyProfile && currentUser != null && !currentUser.isAnonymous)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _toggleFollow(currentUser.uid, widget.userId, isFollowing),
                  child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          otherUserId: widget.userId,
                          otherUserName: displayName,
                        ),
                      ),
                    );
                  },
                  child: const Text('Message'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // WIDGET FOR POSTS LIST
  Widget _buildPostsList(User? currentUser, bool isMyProfile) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('artifacts/$APP_ID/public/data/posts')
          .where('authorId', isEqualTo: widget.userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const FeedSkeleton();
        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isMyProfile ? 'You have no posts yet.' : 'This user has no posts yet.'),
                  if (isMyProfile) ...[
                    const SizedBox(height: 16),
                    FoutaButton(
                      label: 'Create Post',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreatePostScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        
        final docs = snapshot.data!.docs;
        DocumentSnapshot? pinned;
        if (_pinnedPostId != null) {
          try {
            pinned = docs.firstWhere((d) => d.id == _pinnedPostId);
          } catch (_) {}
        }
        final ordered = <DocumentSnapshot>[];
        if (pinned != null) {
          ordered.add(pinned);
        }
        ordered.addAll(docs.where((d) => d.id != _pinnedPostId));

        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: ordered.length,
          itemBuilder: (context, index) {
            final doc = ordered[index];
            final post = doc.data() as Map<String, dynamic>;
            return Column(
              children: [
                if (index == 0 && _pinnedPostId != null)
                  Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    padding: const EdgeInsets.all(8),
                    child: const Text('Pinned Post'),
                  ),
                PostCardWidget(
                  postId: doc.id,
                  post: post,
                  currentUser: currentUser,
                  appId: APP_ID,
                  onMessage: _showMessage,
                  isDataSaverOn: _isDataSaverOn,
                  isOnMobileData: _isOnMobileData,
                ),
                if (isMyProfile)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        if (_pinnedPostId == doc.id) {
                          await _profileService.unpinPost(widget.userId);
                          setState(() => _pinnedPostId = null);
                        } else {
                          await _profileService.pinPost(widget.userId, doc.id);
                          setState(() => _pinnedPostId = doc.id);
                        }
                      },
                      child:
                          Text(_pinnedPostId == doc.id ? 'Unpin' : 'Pin'),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // WIDGET FOR MEDIA GRID
  Widget _buildMediaGrid(User? currentUser) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('artifacts/$APP_ID/public/data/posts')
          .where('authorId', isEqualTo: widget.userId)
          .where('mediaType', whereIn: ['image', 'video']) // FIX: Corrected query
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const FeedSkeleton();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          final bool isMyProfile = currentUser != null && currentUser.uid == widget.userId;
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No media posted yet.'),
                  if (isMyProfile) ...[
                    const SizedBox(height: 16),
                    FoutaButton(
                      label: 'Add Media',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreatePostScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        final posts = snapshot.data!.docs;
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index].data() as Map<String, dynamic>;
            return _MediaGridTile(
              postId: posts[index].id,
              post: post,
            );
          },
        );
      },
    );
  }

  Widget _buildAboutSection() {
    final data = _userData ?? {};
    final links = (data['links'] as List?)?.cast<String>() ?? const [];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if ((data['bio'] ?? '').toString().isNotEmpty)
          Text(data['bio']),
        if ((data['location'] ?? '').toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('Location: ${data['location']}'),
          ),
        if ((data['pronouns'] ?? '').toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('Pronouns: ${data['pronouns']}'),
          ),
        if (links.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text('Links:'),
          ),
          for (final l in links)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(l),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isMyProfile = currentUser?.uid == widget.userId;

    return widget.userId.isEmpty
        ? const Center(child: Text('User ID is missing.'))
        : Scaffold(
            body: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(widget.userId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ProfileSkeleton();
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('User not found.'));
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _userData = userData;
                  final newImage = userData['profileImageUrl'] ?? '';
                  final newPinned = userData['pinnedPostId'];
                  final newCreator = userData['isCreator'] == true;
                  setState(() {
                    _currentProfileImageUrl = newImage;
                    _pinnedPostId = newPinned;
                    _isCreator = newCreator;
                  });
                  if (newCreator) {
                    _loadCreatorInsights(widget.userId);
                  }
                });

                return NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: _buildProfileHeader(userData, isMyProfile, currentUser),
                      ),
                      SliverPersistentHeader(
                        delegate: _SliverTabBarDelegate(
                          TabBar(
                            controller: _tabController,
                            labelColor:
                                Theme.of(context).colorScheme.onSurface,
                            unselectedLabelColor: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            tabs: const [
                              Tab(text: 'Posts'),
                              Tab(text: 'Shorts'),
                              Tab(text: 'About'),
                            ],
                          ),
                        ),
                        pinned: true,
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPostsList(currentUser, isMyProfile),
                      _buildMediaGrid(currentUser),
                      _buildAboutSection(),
                    ],
                  ),
                );
              },
            ),
          );
  }
}

// MEDIA GRID TILE WIDGET
class _MediaGridTile extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> post;
  const _MediaGridTile({required this.postId, required this.post});

  @override
  Widget build(BuildContext context) {
    final String mediaUrl = post['mediaUrl'] ?? '';
    final String mediaType = post['mediaType'] ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId))
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: mediaUrl,
              fit: BoxFit.cover,
              progressIndicatorBuilder: (context, url, progress) => Container(
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            if (mediaType == 'video')
              Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.play_circle_filled,
                    color: Theme.of(context).colorScheme.onPrimary, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

// HELPER CLASS FOR STICKY TAB BAR
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

class EditProfileScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> initialData;
  const EditProfileScreen({super.key, required this.uid, required this.initialData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _displayName;
  late final TextEditingController _bio;
  late final TextEditingController _links;
  late final TextEditingController _location;
  late final TextEditingController _pronouns;
  late bool _isCreator;
  final ProfileService _service = ProfileService();

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _displayName = TextEditingController(text: data['displayName'] ?? '');
    _bio = TextEditingController(text: data['bio'] ?? '');
    _links = TextEditingController(text: (data['links'] as List?)?.join('\n') ?? '');
    _location = TextEditingController(text: data['location'] ?? '');
    _pronouns = TextEditingController(text: data['pronouns'] ?? '');
    _isCreator = data['isCreator'] == true;
  }

  @override
  void dispose() {
    _displayName.dispose();
    _bio.dispose();
    _links.dispose();
    _location.dispose();
    _pronouns.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final links = _links.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    await _service.updateProfile(
      widget.uid,
      displayName: _displayName.text.trim(),
      bio: _bio.text.trim(),
      links: links,
      location: _location.text.trim(),
      pronouns: _pronouns.text.trim(),
    );
    await _service.toggleCreatorMode(widget.uid, _isCreator);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
              controller: _displayName,
              decoration: const InputDecoration(labelText: 'Display Name')),
          TextField(controller: _bio, decoration: const InputDecoration(labelText: 'Bio')),
          TextField(
              controller: _links,
              decoration: const InputDecoration(labelText: 'Links (one per line)')),
          TextField(
              controller: _location,
              decoration: const InputDecoration(labelText: 'Location')),
          TextField(
              controller: _pronouns,
              decoration: const InputDecoration(labelText: 'Pronouns')),
          SwitchListTile(
            title: const Text('Creator Mode'),
            value: _isCreator,
            onChanged: (v) => setState(() => _isCreator = v),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}

