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
import 'package:flutter/foundation.dart' show kIsWeb, mapEquals;

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
import 'package:fouta_app/widgets/safe_stream_builder.dart';
import 'package:fouta_app/widgets/safe_future_builder.dart';
import 'package:fouta_app/utils/async_guard.dart';
import 'package:fouta_app/screens/profile/profile_header.dart';
import 'package:fouta_app/widgets/progressive_image.dart';

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
  Map<String, dynamic>? _lastUserData;
  bool _loadingUser = true;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _postsStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _mediaStream;

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
    _userStream = widget.firestore
        .collection('artifacts/$APP_ID/public/data/users')
        .doc(widget.userId)
        .snapshots();
    _postsStream = widget.firestore
        .collection('artifacts/$APP_ID/public/data/posts')
        .where('authorId', isEqualTo: widget.userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
    _mediaStream = widget.firestore
        .collection('artifacts/$APP_ID/public/data/posts')
        .where('authorId', isEqualTo: widget.userId)
        .where('mediaType', whereIn: ['image', 'video'])
        .orderBy('timestamp', descending: true)
        .snapshots();
    _userSubscription = _userStream.listen((snapshot) {
      final data = snapshot.data();
      _loadingUser = false;
      if (data == null) {
        mountedSetState(this, () {
          _userData = null;
        });
        return;
      }
      if (!mapEquals(_lastUserData, data)) {
        _lastUserData = Map<String, dynamic>.from(data);
        mountedSetState(this, () {
          _userData = data;
          _currentProfileImageUrl = data['profileImageUrl'] ?? '';
          _pinnedPostId = data['pinnedPostId'];
          _isCreator = data['isCreator'] == true;
        });
        if (_isCreator) {
          _loadCreatorInsights(widget.userId);
        }
      }
    });
    _loadDataSaverPreference();
    Connectivity().checkConnectivity().then((result) {
      mountedSetState(this, () {
        _isOnMobileData = result is List<ConnectivityResult>
            ? result.contains(ConnectivityResult.mobile)
            : result == ConnectivityResult.mobile;
      });
    });
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      mountedSetState(this, () {
        _isOnMobileData = results.contains(ConnectivityResult.mobile);
      });
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _bioController.dispose();
    _tabController.dispose();
    _connectivitySubscription?.cancel();
    _userSubscription?.cancel();
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
      mountedSetState(this, () {
        _isDataSaverOn = doc.data()?['dataSaver'] ?? true;
      });
    }
  }

  Future<void> _loadCreatorInsights(String uid) async {
    final posts = await _insights.countPostsLastNDays(uid, 7);
    final engagement = await _insights.sumEngagementLastNDays(uid, 7);
    mountedSetState(this, () {
      _posts7d = posts;
      _engagement7d = engagement;
    });
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

  void _onAvatarTap() {
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
    mountedSetState(this, () {
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
      mountedSetState(this, () {
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
        mountedSetState(this, () {
          _isUploading = false;
        });
        return;
      } finally {
        mountedSetState(this, () {
          _isUploading = false;
        });
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
      mountedSetState(this, () {
        _isEditing = false;
        _newProfileImage = null;
        _uploadProgress = 0.0;
      });
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
                return SafeFutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection('artifacts/$APP_ID/public/data/users')
                      .doc(userId)
                      .get(),
                  empty: const ListTile(title: Text('Loading...')),
                  builder: (context, snapshot) {
                    if (!snapshot.data!.exists) {
                      return const ListTile(title: Text('Unknown User'));
                    }
                    final userData = snapshot.data!.data()!;
                    final String displayName =
                        userData['displayName'] ?? 'Unknown User';
                    final String profileImageUrl =
                        userData['profileImageUrl'] ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: profileImageUrl.isNotEmpty
                            ? CachedNetworkImageProvider(profileImageUrl)
                            : null,
                        child: profileImageUrl.isEmpty
                            ? Icon(Icons.person,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimary)
                            : null,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceVariant,
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


  // WIDGET FOR POSTS LIST
  Widget _buildPostsList(User? currentUser, bool isMyProfile) {
    return SafeStreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _postsStream,
      empty: const FeedSkeleton(),
      builder: (context, snapshot) {
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isMyProfile
                      ? 'You have no posts yet.'
                      : 'This user has no posts yet.'),
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
        DocumentSnapshot<Map<String, dynamic>>? pinned;
        if (_pinnedPostId != null) {
          try {
            pinned = docs.firstWhere((d) => d.id == _pinnedPostId);
          } catch (_) {}
        }
        final ordered = <DocumentSnapshot<Map<String, dynamic>>>[];
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
              final post = doc.data();
              if (post == null) return const SizedBox.shrink();
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
                            mountedSetState(this, () {
                              _pinnedPostId = null;
                            });
                          } else {
                            await _profileService.pinPost(widget.userId, doc.id);
                            mountedSetState(this, () {
                              _pinnedPostId = doc.id;
                            });
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
    return SafeStreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _mediaStream,
      empty: const FeedSkeleton(),
      builder: (context, snapshot) {
        final posts = snapshot.data!.docs;
        if (posts.isEmpty) {
          final bool isMyProfile =
              currentUser != null && currentUser.uid == widget.userId;
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
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index].data();
              if (post == null) return const SizedBox.shrink();
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

    if (widget.userId.isEmpty) {
      return const Center(child: Text('User ID is missing.'));
    }
    if (_loadingUser) {
      return const ProfileSkeleton();
    }
    if (_userData == null) {
      return const Center(child: Text('User not found.'));
    }

    final userData = _userData!;
    final String displayName = userData['displayName'] ?? 'No Name';
    final String bio = userData['bio'] ?? 'No bio yet.';
    final Timestamp? createdAt = userData['createdAt'] as Timestamp?;
    final List<dynamic> followers = userData['followers'] ?? [];
    final List<dynamic> following = userData['following'] ?? [];
    final bool isFollowing = followers.contains(currentUser?.uid);

    if (_isEditing) {
      _bioController.text = bio;
    }

    final header = ProfileHeader(
      userId: widget.userId,
      displayName: displayName,
      bio: bio,
      joinedDate: _formatTimestamp(createdAt),
      isMyProfile: isMyProfile,
      isEditing: _isEditing,
      bioController: _bioController,
      profileImageUrl: _currentProfileImageUrl,
      newProfileImage: _newProfileImage?.file,
      isUploading: _isUploading,
      uploadProgress: _uploadProgress,
      followers: followers,
      following: following,
      onAvatarTap: isMyProfile ? _onAvatarTap : () {},
      onEditPressed: isMyProfile
          ? () {
              if (_isEditing) {
                _updateProfile(_currentProfileImageUrl);
              } else {
                mountedSetState(this, () {
                  _isEditing = true;
                });
              }
            }
          : () {},
      onFollowersTap:
          () => _showUserListDialog(context, followers, 'Followers'),
      onFollowingTap:
          () => _showUserListDialog(context, following, 'Following'),
      creatorStats: _isCreator
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _dashboardTile(context, 'Followers', followers.length),
                _dashboardTile(context, '7-day posts', _posts7d),
                _dashboardTile(context, '7-day engagement', _engagement7d),
              ],
            )
          : null,
    );

    final Widget actionButtons = isMyProfile
        ? Padding(
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
          )
        : (currentUser != null && !currentUser.isAnonymous)
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _toggleFollow(
                        currentUser.uid, widget.userId, isFollowing),
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
              )
            : const SizedBox.shrink();

    final headerSection = Column(
      children: [
        header,
        if (isMyProfile || (currentUser != null && !currentUser.isAnonymous))
          actionButtons,
      ],
    );

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(child: headerSection),
            SliverPersistentHeader(
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).colorScheme.onSurface,
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
            ProgressiveImage(
              imageUrl: mediaUrl,
              thumbUrl: post['thumbUrl'] ?? mediaUrl,
              fit: BoxFit.cover,
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
            onChanged: (v) => mountedSetState(this, () {
              _isCreator = v;
            }),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}

