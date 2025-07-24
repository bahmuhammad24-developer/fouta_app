// lib/screens/home_screen.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fouta_app/services/video_cache_service.dart';
import 'package:fouta_app/services/video_player_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/screens/events_list_screen.dart';
import 'package:fouta_app/screens/notifications_screen.dart';
import 'package:fouta_app/screens/unified_settings_screen.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:badges/badges.dart' as badges;

import 'package:fouta_app/main.dart'; // Import APP_ID
import 'package:fouta_app/screens/chat_screen.dart';
import 'package:fouta_app/screens/create_post_screen.dart';
import 'package:fouta_app/screens/new_chat_screen.dart';
import 'package:fouta_app/screens/profile_screen.dart';
import 'package:fouta_app/widgets/post_card_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isNavBarVisible = true;
  StreamSubscription? _unreadChatsSubscription;
  Stream<int>? _unreadNotificationsStream;
  int _unreadChatsCount = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && !currentUser.isAnonymous) {
      final userRef = FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(currentUser.uid);

      _unreadNotificationsStream = userRef
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);

      _unreadChatsSubscription = userRef.snapshots().listen((snapshot) {
        if (mounted) {
          setState(() {
            _unreadChatsCount = (snapshot.data()?['unreadMessageCount'] ?? 0) as int;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _unreadChatsSubscription?.cancel();
    super.dispose();
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: msg.contains('successful') ? Colors.green : Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _setNavBarVisibility(bool isVisible) {
    if (_isNavBarVisible != isVisible) {
      setState(() {
        _isNavBarVisible = isVisible;
      });
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildOffstageNavigator(int index, Widget child) {
    return Offstage(
      offstage: _selectedIndex != index,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (routeSettings) {
          return MaterialPageRoute(
            builder: (context) => child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final navigator = _navigatorKeys[_selectedIndex].currentState;
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getAppBarTitle()),
          actions: [
            _NotificationsButton(unreadStream: _unreadNotificationsStream),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ],
        ),
        endDrawer: _AppDrawer(showMessage: _showMessage),
        body: IndexedStack(
          index: _selectedIndex,
          children: <Widget>[
            _buildOffstageNavigator(0, const FeedTab()),
            _buildOffstageNavigator(1, ChatsTab(setNavBarVisibility: _setNavBarVisibility)),
            _buildOffstageNavigator(2, const PeopleTab()),
            _buildOffstageNavigator(3, ProfileScreen(userId: currentUser?.uid ?? '')),
          ],
        ),
        floatingActionButton: _isNavBarVisible ? const _CreatePostFab() : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _isNavBarVisible
            ? _BottomNavBar(
                selectedIndex: _selectedIndex,
                unreadChatsCount: _unreadChatsCount,
                onItemTapped: _onItemTapped,
              )
            : null,
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Fouta';
      case 1:
        return 'Chats';
      case 2:
        return 'People';
      case 3:
        return 'Profile';
      default:
        return 'Fouta';
    }
  }
}

// --- STATIC OR REFACTORED WIDGETS FOR PERFORMANCE ---

class _NotificationsButton extends StatelessWidget {
  final Stream<int>? unreadStream;
  const _NotificationsButton({required this.unreadStream});

  Future<void> _markNotificationsAsRead(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final notificationsRef = FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(currentUser.uid).collection('notifications');
    final unreadSnapshot = await notificationsRef.where('isRead', isEqualTo: false).get();
    if (unreadSnapshot.docs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in unreadSnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: unreadStream,
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        return badges.Badge(
          showBadge: unreadCount > 0,
          badgeStyle: badges.BadgeStyle(badgeColor: Theme.of(context).colorScheme.error),
          badgeContent: Text(
            unreadCount > 99 ? '99+' : '$unreadCount',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          position: badges.BadgePosition.topEnd(top: 0, end: 3),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () {
              _markNotificationsAsRead(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
            },
          ),
        );
      },
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final void Function(String) showMessage;
  const _AppDrawer({required this.showMessage});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset('assets/images/fouta_logo_transparent.png'),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.event_outlined),
            title: const Text('Events'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EventsListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UnifiedSettingsScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              showMessage('Fouta App v2.4.0');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              showMessage('Logged out successfully.');
            },
          ),
        ],
      ),
    );
  }
}

class _CreatePostFab extends StatelessWidget {
  const _CreatePostFab();
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "Create New Post",
      child: FloatingActionButton(
        heroTag: 'createPostFab',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen())),
        child: const Icon(Icons.add),
        shape: const CircleBorder(),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final int unreadChatsCount;
  final void Function(int) onItemTapped;

  const _BottomNavBar({
    required this.selectedIndex,
    required this.unreadChatsCount,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _BottomNavItem(
            icon: selectedIndex == 0 ? Icons.home : Icons.home_outlined,
            isSelected: selectedIndex == 0,
            onTap: () => onItemTapped(0),
            tooltip: 'Feed',
          ),
          badges.Badge(
            showBadge: unreadChatsCount > 0,
            badgeStyle: badges.BadgeStyle(badgeColor: Theme.of(context).colorScheme.error),
            badgeContent: Text(
              unreadChatsCount > 99 ? '99+' : '$unreadChatsCount',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            position: badges.BadgePosition.topEnd(top: -10, end: -12),
            child: _BottomNavItem(
              icon: selectedIndex == 1 ? Icons.chat_bubble : Icons.chat_bubble_outline,
              isSelected: selectedIndex == 1,
              onTap: () => onItemTapped(1),
              tooltip: 'Chats',
            ),
          ),
          const SizedBox(width: 48), // The space for the FAB
          _BottomNavItem(
            icon: selectedIndex == 2 ? Icons.people : Icons.people_outlined,
            isSelected: selectedIndex == 2,
            onTap: () => onItemTapped(2),
            tooltip: 'People',
          ),
          _BottomNavItem(
            icon: selectedIndex == 3 ? Icons.person : Icons.person_outlined,
            isSelected: selectedIndex == 3,
            onTap: () => onItemTapped(3),
            tooltip: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;

  const _BottomNavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.white,
      onPressed: onTap,
      tooltip: tooltip,
    );
  }
}


// --- TAB WIDGETS ---

class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  bool _showFollowingFeed = false;
  List<String> _currentUserFollowingIds = [];
  StreamSubscription? _followingSubscription;
  final VideoCacheService _videoCacheService = VideoCacheService();
  int _lastPrecachedIndex = 0;

  // Pagination State
  List<DocumentSnapshot> _posts = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  final int _postsLimit = 15;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setupFollowingListener();
    _scrollController.addListener(_scrollListener);
    _fetchFirstPosts();
  }

  void _setupFollowingListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && !currentUser.isAnonymous) {
      _followingSubscription = FirebaseFirestore.instance
          .collection('artifacts/$APP_ID/public/data/users')
          .doc(currentUser.uid)
          .snapshots()
          .listen((userDoc) {
        if (userDoc.exists && mounted) {
          setState(() {
            _currentUserFollowingIds = List<String>.from(userDoc.data()?['following'] ?? []);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _followingSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: msg.contains('successful') ? Colors.green : Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _fetchFirstPosts() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('artifacts/$APP_ID/public/data/posts')
        .orderBy('timestamp', descending: true)
        .limit(_postsLimit);

    final querySnapshot = await query.get();

    if (mounted) {
      setState(() {
        _posts = querySnapshot.docs;
        if (_posts.isNotEmpty) {
          _lastDocument = querySnapshot.docs.last;
        }
        _hasMore = querySnapshot.docs.length == _postsLimit;
        _isLoading = false;
      });
      // Start precaching after first fetch
      _precacheNextVideos(0);
    }
  }

  Future<void> _fetchMorePosts() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('artifacts/$APP_ID/public/data/posts')
        .orderBy('timestamp', descending: true)
        .startAfterDocument(_lastDocument!)
        .limit(_postsLimit);

    final querySnapshot = await query.get();

    if (mounted) {
      setState(() {
        _posts.addAll(querySnapshot.docs);
        if (querySnapshot.docs.isNotEmpty) {
          _lastDocument = querySnapshot.docs.last;
        }
        _hasMore = querySnapshot.docs.length == _postsLimit;
        _isLoading = false;
      });
    }
  }

  // LOGIC FOR PRE-CACHING
  void _precacheNextVideos(int lastVisibleIndex) {
    // Look ahead 3 posts from the last visible one.
    final precacheStartIndex = lastVisibleIndex + 1;
    final precacheEndIndex = precacheStartIndex + 3;

    if (precacheStartIndex > _lastPrecachedIndex) {
      _lastPrecachedIndex = precacheStartIndex;

      for (int i = precacheStartIndex; i < precacheEndIndex && i < _posts.length; i++) {
        final postData = _posts[i].data() as Map<String, dynamic>;
        if (postData['mediaType'] == 'video' && postData['mediaUrl'] != null) {
          _videoCacheService.precacheVideo(postData['mediaUrl']);
        }
      }
    }
  }

  void _scrollListener() {
    // Logic for pagination
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchMorePosts();
    }

    // Logic for proactive caching
    // This is a simple estimation. A more complex implementation could use item keys and extents.
    double avgItemHeight = 400; // A rough estimate of post card height
    int lastVisibleIndex = (_scrollController.position.pixels / avgItemHeight).floor();
    _precacheNextVideos(lastVisibleIndex);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final filteredPosts = _posts.where((doc) {
      final postData = doc.data() as Map<String, dynamic>;
      final postAuthorId = postData['authorId'] ?? '';
      if (postAuthorId.isEmpty) return false;

      final postVisibility = postData['postVisibility'] ?? 'everyone';

      if (_showFollowingFeed) {
        return currentUser != null && _currentUserFollowingIds.contains(postAuthorId);
      } else {
        if (postVisibility == 'everyone') return true;
        if (postVisibility == 'followers') {
          return currentUser != null && (currentUser.uid == postAuthorId || _currentUserFollowingIds.contains(postAuthorId));
        }
      }
      return false;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        _hasMore = true;
        _lastDocument = null;
        _posts.clear();
        await _fetchFirstPosts();
      },
      color: Theme.of(context).colorScheme.primary,
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Explore'),
                  selected: !_showFollowingFeed,
                  onSelected: (selected) => setState(() => _showFollowingFeed = !selected),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                      color: !_showFollowingFeed ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Following'),
                  selected: _showFollowingFeed,
                  onSelected: (selected) => setState(() => _showFollowingFeed = selected),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                      color: _showFollowingFeed ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color),
                ),
              ],
            ),
          ),
          Expanded(
            child: (_posts.isEmpty && _isLoading)
                ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary))
                : (filteredPosts.isEmpty)
                    ? const Center(child: Text('No posts to display.', style: TextStyle(fontSize: 16, color: Colors.grey)))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                        itemCount: filteredPosts.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == filteredPosts.length) {
                            return _isLoading
                                ? const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()))
                                : const SizedBox.shrink();
                          }

                          final postDoc = filteredPosts[index];
                          final post = postDoc.data() as Map<String, dynamic>;
                          final postId = postDoc.id;

                          return PostCardWidget(
                            key: ValueKey(postId),
                            post: post,
                            postId: postId,
                            currentUser: currentUser,
                            appId: APP_ID,
                            onMessage: _showMessage,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class ChatsTab extends StatefulWidget {
  final Function(bool) setNavBarVisibility;
  const ChatsTab({super.key, required this.setNavBarVisibility});

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final DateTime date = timestamp.toDate();
    return DateFormat('HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.isAnonymous) {
      return const Center(child: Text('Please log in to view your chats.'));
    }
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      color: Theme.of(context).colorScheme.primary,
      child: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('artifacts/$APP_ID/public/data/chats')
                .where('participants', arrayContains: currentUser.uid)
                .orderBy('lastMessageTimestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No active chats. Start a new one!'));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final chatDoc = snapshot.data!.docs[index];
                  final chat = chatDoc.data() as Map<String, dynamic>;
                  return _ChatListItem(
                    chat: chat,
                    chatDocId: chatDoc.id,
                    currentUserId: currentUser.uid,
                    setNavBarVisibility: widget.setNavBarVisibility,
                    formatTimestamp: _formatTimestamp,
                  );
                },
              );
            },
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              heroTag: 'newChatFab',
              onPressed: () async {
                widget.setNavBarVisibility(false);
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const NewChatScreen()));
                widget.setNavBarVisibility(true);
              },
              child: const Icon(Icons.message),
              tooltip: 'Start New Chat',
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  const _ChatListItem({
    required this.chat,
    required this.chatDocId,
    required this.currentUserId,
    required this.setNavBarVisibility,
    required this.formatTimestamp,
  });

  final Map<String, dynamic> chat;
  final String chatDocId;
  final String currentUserId;
  final Function(bool) setNavBarVisibility;
  final String Function(Timestamp?) formatTimestamp;

  @override
  Widget build(BuildContext context) {
    final bool isGroupChat = chat['isGroupChat'] ?? false;
    final unreadCounts = chat['unreadCounts'] as Map<String, dynamic>? ?? {};
    final unreadCount = (unreadCounts[currentUserId] as int?) ?? 0;

    Widget titleWidget;
    Widget avatarWidget;

    if (isGroupChat) {
      titleWidget = Text(chat['groupName'] ?? 'Group Chat', style: const TextStyle(fontWeight: FontWeight.bold));
      avatarWidget = CircleAvatar(
        backgroundImage: (chat['groupImageUrl'] != null && chat['groupImageUrl']!.isNotEmpty)
            ? NetworkImage(chat['groupImageUrl'])
            : null,
        child: (chat['groupImageUrl'] == null || chat['groupImageUrl']!.isEmpty) ? const Icon(Icons.group) : null,
      );
    } else {
      final otherUserId = (List<String>.from(chat['participants'])).firstWhere((uid) => uid != currentUserId, orElse: () => '');
      if (otherUserId.isEmpty) return const SizedBox.shrink();

      titleWidget = FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(otherUserId).get(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Text('Loading...');
          return Text(userSnapshot.data!['displayName'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold));
        },
      );
      avatarWidget = FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(otherUserId).get(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const CircleAvatar(child: Icon(Icons.person));
          final profileImageUrl = userSnapshot.data!['profileImageUrl'] ?? '';
          return CircleAvatar(
            backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
            child: profileImageUrl.isEmpty ? const Icon(Icons.person) : null,
          );
        },
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: avatarWidget,
        title: titleWidget,
        subtitle: Text(chat['lastMessage'] ?? 'No messages yet', maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: unreadCount > 0
            ? badges.Badge(
                badgeStyle: badges.BadgeStyle(badgeColor: Theme.of(context).colorScheme.secondary),
                badgeContent: Text('$unreadCount', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            : Text(formatTimestamp(chat['lastMessageTimestamp'] as Timestamp?)),
        onTap: () async {
          setNavBarVisibility(false);
          await Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(chatId: chatDocId)));
          setNavBarVisibility(true);
        },
      ),
    );
  }
}

class PeopleTab extends StatefulWidget {
  const PeopleTab({super.key});

  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> {
  final TextEditingController _userSearchController = TextEditingController();

  @override
  void dispose() {
    _userSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.isAnonymous) {
      return const Center(child: Text('Please log in to view other users.'));
    }
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      color: Theme.of(context).colorScheme.primary,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _userSearchController,
              decoration: const InputDecoration(hintText: 'Search users by name...', prefixIcon: Icon(Icons.search)),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('artifacts/$APP_ID/public/data/users')
                  .where('isDiscoverable', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No other users found.'));
                }
                final searchText = _userSearchController.text.toLowerCase().trim();
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final userData = doc.data() as Map<String, dynamic>;
                  final displayName = (userData['displayName'] ?? '').toLowerCase();
                  return doc.id != currentUser.uid && displayName.contains(searchText);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('No matching users found.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 80),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final userDoc = filteredDocs[index];
                    final userData = userDoc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: (userData['profileImageUrl'] != null && userData['profileImageUrl'].isNotEmpty)
                              ? NetworkImage(userData['profileImageUrl'])
                              : null,
                          child: (userData['profileImageUrl'] == null || userData['profileImageUrl'].isEmpty)
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                          backgroundColor: Colors.grey[300],
                        ),
                        title: Text(userData['displayName'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(userData['bio'] ?? 'No bio', maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: userDoc.id))),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}