// lib/screens/profile_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fouta_app/screens/post_detail_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:fouta_app/main.dart'; // Import APP_ID
import 'package:fouta_app/screens/chat_screen.dart';
import 'package:fouta_app/widgets/full_screen_image_viewer.dart';
import 'package:fouta_app/widgets/post_card_widget.dart';
import 'package:fouta_app/widgets/fouta_button.dart';
import 'package:fouta_app/screens/create_post_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fouta_app/utils/firestore_paths.dart';
import 'package:fouta_app/widgets/skeletons/profile_skeleton.dart';
import 'package:fouta_app/utils/snackbar.dart';
import 'package:fouta_app/widgets/skeletons/feed_skeleton.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final bool initialIsEditing;
  const ProfileScreen({super.key, required this.userId, this.initialIsEditing = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

// Add SingleTickerProviderStateMixin for the TabController
class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final _bioController = TextEditingController();
  late bool _isEditing;
  String _currentProfileImageUrl = '';
  XFile? _newProfileImageFile;
  Uint8List? _newProfileImageBytes;
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();

  bool _isDataSaverOn = true;
  bool _isOnMobileData = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // TAB CONTROLLER SETUP
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialIsEditing;
    _tabController = TabController(length: 2, vsync: this);
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

  Future<void> _pickProfileImage() async {
    if (_isUploading) {
      _showMessage('Upload in progress. Please wait.');
      return;
    }

    XFile? pickedFile;
    try {
      pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      _showMessage('Error picking image: $e');
      return;
    }

    if (pickedFile != null) {
      _showMessage('Image selected. Tap the checkmark to save changes.');
      setState(() {
        if (kIsWeb) {
          pickedFile!.readAsBytes().then((bytes) {
            setState(() {
              _newProfileImageBytes = bytes;
            });
          });
        } else {
          _newProfileImageFile = pickedFile;
        }
      });
    } else {
      _showMessage('No image selected.');
    }
  }

  Future<void> _updateProfile(String currentProfileImageUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != widget.userId) {
      _showMessage('You can only edit your own profile.');
      return;
    }

    String? newImageUrl = currentProfileImageUrl;
    if (_newProfileImageFile != null || _newProfileImageBytes != null) {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_profile_pic.jpg');

        UploadTask uploadTask;
        if (kIsWeb && _newProfileImageBytes != null) {
          uploadTask = storageRef.putData(_newProfileImageBytes!);
        } else if (_newProfileImageFile != null) {
          uploadTask = storageRef.putFile(File(_newProfileImageFile!.path));
        } else {
          _showMessage('Invalid media data for upload.');
          if (mounted) setState(() { _isUploading = false; });
          return;
        }

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if(mounted) {
            setState(() {
              _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
            });
          }
        });

        await uploadTask.whenComplete(() async {
          newImageUrl = await storageRef.getDownloadURL();
          _showMessage('Profile image uploaded successfully!');
        });
      } on FirebaseException catch (e) {
        _showMessage('Profile image upload failed: ${e.message}');
        if(mounted) setState(() => _isUploading = false);
        return;
      } finally {
        if(mounted) setState(() => _isUploading = false);
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
          _newProfileImageFile = null;
          _newProfileImageBytes = null;
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

    showDialog(
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImageViewer(imageUrl: _currentProfileImageUrl),
                  ),
                );
              }
            } : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: (_newProfileImageBytes != null && kIsWeb)
                      ? MemoryImage(_newProfileImageBytes!)
                      : (_newProfileImageFile != null && !kIsWeb)
                          ? FileImage(File(_newProfileImageFile!.path)) as ImageProvider
                          : (_currentProfileImageUrl.isNotEmpty ? CachedNetworkImageProvider(_currentProfileImageUrl) : null),
                  child: (_currentProfileImageUrl.isEmpty && _newProfileImageFile == null && _newProfileImageBytes == null)
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
        
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final post = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return PostCardWidget(
              postId: snapshot.data!.docs[index].id,
              post: post,
              currentUser: currentUser,
              appId: APP_ID,
              onMessage: _showMessage,
              isDataSaverOn: _isDataSaverOn,
              isOnMobileData: _isOnMobileData,
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
                  if (mounted && _currentProfileImageUrl != (userData['profileImageUrl'] ?? '')) {
                    setState(() {
                      _currentProfileImageUrl = userData['profileImageUrl'] ?? '';
                    });
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
                              Tab(icon: Icon(Icons.grid_on)),
                              Tab(icon: Icon(Icons.photo_library)),
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
              placeholder: (context, url) => Container(
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            if(mediaType == 'video')
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.play_circle_filled, color: Theme.of(context).colorScheme.onPrimary, size: 20),
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