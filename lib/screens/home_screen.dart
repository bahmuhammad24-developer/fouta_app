// lib/screens/home_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:fouta_app/services/video_cache_service.dart';
import 'package:fouta_app/services/video_player_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:fouta_app/screens/events_list_screen.dart';
import 'package:fouta_app/screens/notifications_screen.dart';
import 'package:fouta_app/screens/unified_settings_screen.dart';
import 'package:fouta_app/widgets/stories_tray.dart';
import 'package:fouta_app/devtools/diagnostics_panel.dart';
import 'package:fouta_app/utils/date_utils.dart';
import 'dart:async';
import 'package:badges/badges.dart' as badges;
// Explicitly import ScrollDirection enum for userScrollDirection checks
// Import ScrollDirection from widgets to compare user scroll direction
import 'package:flutter/widgets.dart' show ScrollDirection, AutomaticKeepAliveClientMixin;

import 'package:fouta_app/main.dart'; // Import APP_ID
import 'package:fouta_app/screens/chat_screen.dart';
import 'package:fouta_app/screens/create_post_screen.dart';
import 'package:fouta_app/features/stories/camera/story_camera_screen.dart';
import 'package:fouta_app/features/stories/composer/create_story_screen.dart';
import 'package:fouta_app/features/stories/viewer/story_viewer_screen.dart';
import 'package:fouta_app/screens/new_chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:fouta_app/services/connectivity_provider.dart';
import 'package:fouta_app/screens/profile_screen.dart';
import 'package:fouta_app/widgets/post_card_widget.dart';
import 'package:fouta_app/utils/firestore_paths.dart';
import 'package:fouta_app/widgets/fouta_button.dart';
import 'package:fouta_app/widgets/fouta_card.dart';
import 'package:fouta_app/widgets/skeletons/feed_skeleton.dart';
import 'package:fouta_app/utils/snackbar.dart';
import 'package:fouta_app/models/story.dart';
import 'package:fouta_app/widgets/system/offline_banner.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isNavBarVisible = true;
  Stream<int>? _unreadNotificationsStream;
  bool _showNewChatFab = true;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
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
      final userRef = FirebaseFirestore.instance
          .collection(FirestorePaths.users())
          .doc(currentUser.uid);

      _unreadNotificationsStream = userRef
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);

    }
  }

  @override
  void dispose() {
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

  void _setNavBarVisibility(bool isVisible) {
    if (_isNavBarVisible == isVisible) return;
    setState(() {
      _isNavBarVisible = isVisible;
    });
  }

  void _setShowNewChatFab(bool show) {
    if (_showNewChatFab == show) return;
    setState(() {
      _showNewChatFab = show;
    });
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

  Widget _buildTabNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => child,
        );
      },
    );
  }
  
  Widget _buildNewChatFab(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'newChatFab',
      onPressed: () async {
        _setShowNewChatFab(false);
        _setNavBarVisibility(false);
        await Navigator.push(context, MaterialPageRoute(builder: (context) => const NewChatScreen()));
        _setNavBarVisibility(true);
        _setShowNewChatFab(true);
      },
      child: const Icon(Icons.message),
      tooltip: 'Start New Chat',
    );
  }

  @override
  Widget build(BuildContext context) {
    
    final currentUser = FirebaseAuth.instance.currentUser;
    final isWide = MediaQuery.of(context).size.width >= 900;

    return WillPopScope(
      onWillPop: () async {
        final currentNavigator =
            _navigatorKeys[_selectedIndex].currentState;
        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
          return false;
        }
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return false;
        }
        return true; // on first tab → allow system back
      },
      child: Scaffold(
          endDrawer: _AppDrawer(showMessage: _showMessage),
          // Show the New Chat FAB only on the chats list screen
          floatingActionButton: (_selectedIndex == 1 && _showNewChatFab)
              ? _buildNewChatFab(context)
              : null,

          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.dynamic_feed_outlined),
                selectedIcon: const _GradientSelectedIcon(Icons.dynamic_feed),
                label: 'Feed',
              ),
              NavigationDestination(
                icon: const Icon(Icons.chat_bubble_outline),
                selectedIcon: const _GradientSelectedIcon(Icons.chat_bubble),
                label: 'Chat',
              ),
              NavigationDestination(
                icon: const Icon(Icons.event_outlined),
                selectedIcon: const _GradientSelectedIcon(Icons.event),
                label: 'Events',
              ),
              NavigationDestination(
                icon: const Icon(Icons.group_outlined),
                selectedIcon: const _GradientSelectedIcon(Icons.group),
                label: 'People',
              ),
              NavigationDestination(
                icon: kDebugMode
                    ? GestureDetector(
                        onLongPress: _openDiagnostics,
                        child: const Icon(Icons.person_outline),
                      )
                    : const Icon(Icons.person_outline),
                selectedIcon: const _GradientSelectedIcon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
          body: Consumer<ConnectivityProvider>(
            builder: (context, connectivity, _) {
              Widget content = NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      title: GestureDetector(
                        onTap: () {
                          _titleTapCount++;
                          if (_titleTapCount >= 5) {
                            _titleTapCount = 0;
                            _openDiagnostics();
                          }
                        },
                        child: Text(_getAppBarTitle()),
                      ),
                      // Keep the app bar visible while scrolling
                      pinned: true,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: 'Create Post',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreatePostScreen(),
                            ),
                          ),
                        ),
                        _NotificationsButton(
                            unreadStream: _unreadNotificationsStream),
                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: () =>
                                Scaffold.of(context).openEndDrawer(),
                          ),
                        ),
                      ],
                    ),
                  ];
                },
                body: IndexedStack(
                  index: _selectedIndex,
                  children: <Widget>[
                    _buildTabNavigator(
                        0, FeedTab(setNavBarVisibility: _setNavBarVisibility)),
                    _buildTabNavigator(
                        1,
                        ChatsTab(
                            setNavBarVisibility: _setNavBarVisibility,
                            setShowNewChatFab: _setShowNewChatFab)),
                    _buildTabNavigator(2, const EventsListScreen()),
                    _buildTabNavigator(3, const PeopleTab()),
                    _buildTabNavigator(
                        4, ProfileScreen(userId: currentUser?.uid ?? '')),
                  ],
                ),
              );

              Widget page;
              if (isWide) {
                page = Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _onItemTapped,
                      labelType: NavigationRailLabelType.selected,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.dynamic_feed_outlined),
                          selectedIcon: Icon(Icons.dynamic_feed),
                          label: Text('Feed'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.chat_bubble_outline),
                          selectedIcon: Icon(Icons.chat_bubble),
                          label: Text('Chat'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.event_outlined),
                          selectedIcon: Icon(Icons.event),
                          label: Text('Events'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.group_outlined),
                          selectedIcon: Icon(Icons.group),
                          label: Text('People'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.person_outline),
                          selectedIcon: Icon(Icons.person),
                          label: Text('Profile'),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                );
              } else {
                page = content;
              }

              return Stack(
                children: [
                  Positioned.fill(child: page),
                  if (!connectivity.isOnline) const OfflineBanner(),
                ],
              );
            },
          ),
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
        return 'Events';
      case 3:
        return 'People';
      case 4:
        return 'Profile';
      default:
        return 'Fouta';
    }
  }
}

class _GradientSelectedIcon extends StatelessWidget {
  final IconData icon;
  const _GradientSelectedIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    const g1 = Color(0xFF7ED6A0); // pastel green
    const g2 = Color(0xFFF5D98B); // pastel gold
    return Stack(
      alignment: Alignment.center,
      children: [
        // subtle glow
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Color(0x337ED6A0), blurRadius: 12, spreadRadius: 1),
            ],
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect bounds) => const LinearGradient(
            colors: [g1, g2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Icon(icon, size: 28, color: Colors.white),
        ),
      ],
    );
  }
}

// --- STATIC OR REFACTORED WIDGETS FOR PERFORMANCE ---

class _NotificationsButton extends StatelessWidget {
  final Stream<int>? unreadStream;
  const _NotificationsButton({required this.unreadStream});

  Future<void> _markNotificationsAsRead(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final notificationsRef = FirebaseFirestore.instance
        .collection(FirestorePaths.users())
        .doc(currentUser.uid)
        .collection('notifications');
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
        return IconButton(
          icon: badges.Badge(
            showBadge: unreadCount > 0,
            badgeStyle: badges.BadgeStyle(
              badgeColor: Theme.of(context).colorScheme.error,
            ),
            badgeContent: Text(
              unreadCount > 99 ? '99+' : '$unreadCount',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 10),
            ),
            position: badges.BadgePosition.topEnd(top: -4, end: -4),
            child: const Icon(Icons.notifications_outlined),
          ),
          tooltip: 'Notifications',
          onPressed: () {
            _markNotificationsAsRead(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
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


// --- TAB WIDGETS ---

class FeedTab extends StatefulWidget {
  final Function(bool) setNavBarVisibility;
  const FeedTab({super.key, required this.setNavBarVisibility});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

// Extend TickerProviderStateMixin to use TabController for the feed toggle
class _FeedTabState extends State<FeedTab> with AutomaticKeepAliveClientMixin {
  bool _showFollowingFeed = false;
  List<String> _currentUserFollowingIds = [];
  StreamSubscription? _followingSubscription;
  final VideoCacheService _videoCacheService = VideoCacheService();
  int _lastPrecachedIndex = 0;

  // Stories currently loaded in the feed
  List<Story> _stories = [];
  int _titleTapCount = 0;


  bool _isDataSaverOn = true;
  bool _isOnMobileData = false;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;



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
    _fetchStories();
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

  void _setupFollowingListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && !currentUser.isAnonymous) {
      _followingSubscription = FirebaseFirestore.instance
          .collection(FirestorePaths.users())
          .doc(currentUser.uid)
          .snapshots()
          .listen((userDoc) {
        if (userDoc.exists && mounted) {
          setState(() {
            _currentUserFollowingIds = List<String>.from(userDoc.data()?['following'] ?? []);
            _isDataSaverOn = userDoc.data()?['dataSaver'] ?? true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _followingSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchStories() async {
    final ownersSnap = await FirebaseFirestore.instance
        .collection(FirestorePaths.stories())
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .get();
    final now = DateTime.now();
    final List<Story> owners = [];
    for (final doc in ownersSnap.docs) {
      final slidesSnap = await doc.reference
          .collection('slides')
          .orderBy('createdAt', descending: true)
          .get();
      final slides = slidesSnap.docs.where((s) {
        final exp = (s['expiresAt'] as Timestamp?)?.toDate();
        if (exp != null) return exp.isAfter(now);
        final created = (s['createdAt'] as Timestamp?)?.toDate();
        return created != null && created.add(const Duration(hours: 24)).isAfter(now);
      }).map((s) {
        final typeStr = (s['type'] as String?) ?? 'image';
        final type = typeStr == 'video' ? MediaType.video : MediaType.image;
        final url = s['url'] as String? ?? '';
        final thumb = s['thumbUrl'] as String?;
        final dur = s['durationMs'] as int?;
        return StoryItem(
          media: MediaItem(
            id: s.id,
            type: type,
            url: url,
            thumbUrl: thumb,
            duration: dur != null ? Duration(milliseconds: dur) : null,
          ),
          createdAt: (s['createdAt'] as Timestamp?)?.toDate(),
          expiresAt: (s['expiresAt'] as Timestamp?)?.toDate(),
        );
      }).toList();
      if (slides.isNotEmpty) {
        owners.add(Story(
          id: doc.id,
          authorId: doc.id,
          postedAt: (doc['updatedAt'] as Timestamp?)?.toDate() ?? now,
          expiresAt: now.add(const Duration(hours: 24)),
          items: slides,
        ));
      }
    }
    if (mounted) {
      setState(() => _stories = owners);
      StoryDiagnostics.instance.owners = owners;
    }
  }

  void _openDiagnostics() {
    if (!kDebugMode) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    DiagnosticsPanel.show(context, uid, onRefresh: _fetchStories);
  }

  Future<void> _onAddStory() async {
    final slide = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StoryCameraScreen()),
    );
    if (slide is StoryItem) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      setState(() {
        final existingIndex = _stories.indexWhere((s) => s.authorId == uid);
        if (existingIndex >= 0) {
          final existing = _stories[existingIndex];
          final updated = Story(
            id: existing.id,
            authorId: existing.authorId,
            postedAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(hours: 24)),
            items: [slide, ...existing.items],
            seen: false,
          );
          _stories.removeAt(existingIndex);
          _stories.insert(0, updated);
        } else {
          _stories.insert(
            0,
            Story(
              id: uid,
              authorId: uid,
              postedAt: DateTime.now(),
              expiresAt: DateTime.now().add(const Duration(hours: 24)),
              items: [slide],
              seen: false,
            ),
          );
        }
        StoryDiagnostics.instance.owners = _stories;
      });
    }
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

  Future<void> _fetchFirstPosts() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection(FirestorePaths.posts())
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
      _precacheNextVideos(0);
    }
  }

  Future<void> _fetchMorePosts() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection(FirestorePaths.posts())
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

  void _precacheNextVideos(int lastVisibleIndex) {
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchMorePosts();
    }
    double avgItemHeight = 400;
    int lastVisibleIndex = (_scrollController.position.pixels / avgItemHeight).floor();
    _precacheNextVideos(lastVisibleIndex);

    // Hide or show the navigation bar based on scroll direction
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      widget.setNavBarVisibility(false);
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      widget.setNavBarVisibility(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
          // Prevent users from vertically dragging to hide the stories tray
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragDown: (_) {},
            onVerticalDragStart: (_) {},
            onVerticalDragUpdate: (_) {},
            onVerticalDragEnd: (_) {},
              child: FoutaCard(
                padding: EdgeInsets.zero,
                // FoutaCard previously expected a [Row] child. Wrapping the
                // stories tray in a Row maintains that contract while letting
                // the tray widget handle its own layout.
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: StoriesTray(
                              stories: _stories,
                              currentUserId:
                                  FirebaseAuth.instance.currentUser?.uid ?? '',
                              onAdd: _onAddStory,
                              onStoryTap: (Story story) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StoryViewerScreen(
                                      stories: [story],
                                    ),
                                    fullscreenDialog: true,
                                  ),
                                );
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Refresh Stories',
                            onPressed: _fetchStories,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          FoutaCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Explore'),
                  selected: !_showFollowingFeed,
                  onSelected: (selected) {
                    setState(() {
                      _showFollowingFeed = false;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Following'),
                  selected: _showFollowingFeed,
                  onSelected: (selected) {
                    setState(() {
                      _showFollowingFeed = true;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: (_posts.isEmpty && _isLoading)
                ? const FeedSkeleton()
                : (filteredPosts.isEmpty)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('No posts to display.',
                                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.outline)),
                            const SizedBox(height: 16),
                            FoutaButton(
                              label: 'Create Post',
                              onPressed: () async {
                                widget.setNavBarVisibility(false);
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CreatePostScreen(),
                                  ),
                                );
                                widget.setNavBarVisibility(true);
                              },
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        // FIX: Removed horizontal padding to make cards wider
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
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
                            isDataSaverOn: _isDataSaverOn,
                            isOnMobileData: _isOnMobileData,
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
  final Function(bool) setShowNewChatFab;
  const ChatsTab({super.key, required this.setNavBarVisibility, required this.setShowNewChatFab});

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> with AutomaticKeepAliveClientMixin {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTimestamp(Timestamp? timestamp) {
    final date = timestamp?.toDate();
    if (date == null) return 'Just now';
    return DateUtilsHelper.formatRelative(date);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.isAnonymous) {
      return const Center(child: Text('Please log in to view your chats.'));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search chats...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirestorePaths.chats())
                .where('participants', arrayContains: currentUser.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Failed to load chats'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No active chats. Start a new one!'),
                      const SizedBox(height: 16),
                      FoutaButton(
                        label: 'Start Chat',
                        onPressed: () async {
                          widget.setNavBarVisibility(false);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NewChatScreen(),
                            ),
                          );
                          widget.setNavBarVisibility(true);
                        },
                      ),
                    ],
                  ),
                );
              }
              final docs = snapshot.data!.docs.toList();
              docs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTs = aData['lastMessageTimestamp'] as Timestamp?;
                final bTs = bData['lastMessageTimestamp'] as Timestamp?;
                if (aTs == null && bTs == null) return 0;
                if (aTs == null) return 1;
                if (bTs == null) return -1;
                return bTs.compareTo(aTs);
              });
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
                itemCount: docs.length,
                separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
                itemBuilder: (context, index) {
                  final chatDoc = docs[index];
                  final chat = chatDoc.data() as Map<String, dynamic>;
                  return _ChatListItem(
                    chat: chat,
                    chatDocId: chatDoc.id,
                    currentUserId: currentUser.uid,
                    setNavBarVisibility: widget.setNavBarVisibility,
                    setShowNewChatFab: widget.setShowNewChatFab,
                    formatTimestamp: _formatTimestamp,
                    searchQuery: _searchQuery,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}


class _ChatListItem extends StatelessWidget {
  const _ChatListItem({
    required this.chat,
    required this.chatDocId,
    required this.currentUserId,
    required this.setNavBarVisibility,
    required this.setShowNewChatFab,
    required this.formatTimestamp,
    required this.searchQuery,
  });

  final Map<String, dynamic> chat;
  final String chatDocId;
  final String currentUserId;
  final Function(bool) setNavBarVisibility;
  final Function(bool) setShowNewChatFab;
  final String Function(Timestamp?) formatTimestamp;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final bool isGroupChat = chat['isGroupChat'] ?? false;
    final unreadCounts = chat['unreadCounts'] as Map<String, dynamic>? ?? {};
    final int unreadCount = (unreadCounts[currentUserId] as int?) ?? 0;
    
    final Map<String, dynamic> typingStatus = chat['typingStatus'] ?? {};
    final otherTypingUsers = typingStatus.entries
      .where((entry) => entry.key != currentUserId && entry.value == true)
      .map((entry) => entry.key)
      .toList();
    final bool isSomeoneTyping = otherTypingUsers.isNotEmpty;

    if (isGroupChat) {
      final String groupName = chat['groupName'] ?? 'Group Chat';
      if (searchQuery.isNotEmpty && !groupName.toLowerCase().contains(searchQuery.toLowerCase())) {
        return const SizedBox.shrink();
      }
      return _buildTile(
        context: context,
        title: groupName,
        subtitle: isSomeoneTyping ? "typing..." : (chat['lastMessage'] ?? '...'),
        imageUrl: chat['groupImageUrl'],
        isGroup: true,
        unreadCount: unreadCount,
        timestamp: formatTimestamp(chat['lastMessageTimestamp'] as Timestamp?),
        onTap: () async {
          setNavBarVisibility(false);
          setShowNewChatFab(false);
          await Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(chatId: chatDocId)));
          setShowNewChatFab(true);
          setNavBarVisibility(true);
        },
      );
    } else {
      // Use denormalized participantDetails to avoid extra Firestore reads
      final Map<String, dynamic>? participantDetails = chat['participantDetails'] as Map<String, dynamic>?;
      if (participantDetails != null && participantDetails.isNotEmpty) {
        // Get other user info
        Map<String, dynamic>? otherUserInfo;
        participantDetails.forEach((uid, info) {
          if (uid != currentUserId) {
            otherUserInfo = Map<String, dynamic>.from(info);
          }
        });
        if (otherUserInfo != null) {
          final displayName = otherUserInfo!['displayName'] ?? 'User';
          if (searchQuery.isNotEmpty && !displayName.toLowerCase().contains(searchQuery.toLowerCase())) {
            return const SizedBox.shrink();
          }
          final imageUrl = otherUserInfo!['profileImageUrl'];
          final bool isOnline = (otherUserInfo!['isOnline'] ?? false) as bool;
          final bool showOnlineStatus = (otherUserInfo!['showOnlineStatus'] ?? false) as bool;
          return _buildTile(
            context: context,
            title: displayName,
            subtitle: isSomeoneTyping ? "typing..." : (chat['lastMessage'] ?? '...'),
            imageUrl: imageUrl,
            isOnline: isOnline,
            showOnlineStatus: showOnlineStatus,
            unreadCount: unreadCount,
            timestamp: formatTimestamp(chat['lastMessageTimestamp'] as Timestamp?),
            onTap: () async {
              setNavBarVisibility(false);
              setShowNewChatFab(false);
              await Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(chatId: chatDocId, otherUserId: null, otherUserName: displayName)));
              setShowNewChatFab(true);
              setNavBarVisibility(true);
            },
          );
        }
      }
      // Fallback: fetch user document if participantDetails is missing
      final otherUserId = (List<String>.from(chat['participants'])).firstWhere((uid) => uid != currentUserId, orElse: () => '');
      if (otherUserId.isEmpty) return const SizedBox.shrink();
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection(FirestorePaths.users())
            .doc(otherUserId)
            .get(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const SizedBox.shrink();
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final String displayName = userData['displayName'] ?? 'User';
          if (searchQuery.isNotEmpty && !displayName.toLowerCase().contains(searchQuery.toLowerCase())) {
            return const SizedBox.shrink();
          }
          return _buildTile(
            context: context,
            title: displayName,
            subtitle: isSomeoneTyping ? "typing..." : (chat['lastMessage'] ?? '...'),
            imageUrl: userData['profileImageUrl'],
            isOnline: userData['isOnline'] ?? false,
            showOnlineStatus: userData['showOnlineStatus'] ?? false,
            unreadCount: unreadCount,
            timestamp: formatTimestamp(chat['lastMessageTimestamp'] as Timestamp?),
            onTap: () async {
              setNavBarVisibility(false);
              setShowNewChatFab(false);
              await Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(chatId: chatDocId, otherUserId: otherUserId, otherUserName: displayName)));
              setShowNewChatFab(true);
              setNavBarVisibility(true);
            },
          );
        },
      );
    }
  }

  Widget _buildTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    String? imageUrl,
    bool isGroup = false,
    bool isOnline = false,
    bool showOnlineStatus = false,
    required int unreadCount,
    required String timestamp,
    required VoidCallback onTap,
  }) {
    return Dismissible(
      key: Key(chatDocId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.outline,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Icon(Icons.archive_outlined, color: Theme.of(context).colorScheme.onPrimary),
      ),
      secondaryBackground: Container(
        color: Theme.of(context).colorScheme.primary,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Icon(Icons.volume_mute_outlined, color: Theme.of(context).colorScheme.onPrimary),
      ),
      confirmDismiss: (direction) async {
        // Placeholder for future functionality
        if (direction == DismissDirection.endToStart) {
          AppSnackBar.show(context, 'Archive not implemented yet.', isError: true);
        } else {
          AppSnackBar.show(context, 'Mute not implemented yet.', isError: true);
        }
        return false;
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? CachedNetworkImageProvider(imageUrl) : null,
              child: (imageUrl == null || imageUrl.isEmpty) ? Icon(isGroup ? Icons.group : Icons.person) : null,
            ),
            if (!isGroup && isOnline && showOnlineStatus)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 3),
                  ),
                ),
              ),
          ],
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitle, 
          maxLines: 1, 
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: subtitle == "typing..." ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(timestamp, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 4),
            if (unreadCount > 0)
              CircleAvatar(
                radius: 10,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text('$unreadCount', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            else 
              const SizedBox(height: 20),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}


class PeopleTab extends StatefulWidget {
  const PeopleTab({super.key});

  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _userSearchController = TextEditingController();
  
  @override
  void dispose() {
    _userSearchController.dispose();
    super.dispose();
  }
  
  void _toggleFollow(String currentUserId, String targetUserId, bool isFollowing) async {
    final currentUserRef = FirebaseFirestore.instance
        .collection(FirestorePaths.users())
        .doc(currentUserId);
    final targetUserRef = FirebaseFirestore.instance
        .collection(FirestorePaths.users())
        .doc(targetUserId);

    if (isFollowing) {
      await currentUserRef.update({'following': FieldValue.arrayRemove([targetUserId])});
      await targetUserRef.update({'followers': FieldValue.arrayRemove([currentUserId])});
    } else {
      await currentUserRef.update({'following': FieldValue.arrayUnion([targetUserId])});
      await targetUserRef.update({'followers': FieldValue.arrayUnion([currentUserId])});
    }
  }
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.isAnonymous) {
      return const Center(child: Text('Please log in to view other users.'));
    }
    
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _userSearchController,
              decoration: const InputDecoration(hintText: 'Search all users...', prefixIcon: Icon(Icons.search)),
              onChanged: (value) => setState(() {}),
            ),
          ),
          TabBar(
            labelColor: Theme.of(context).colorScheme.onSurface,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            tabs: const [
              Tab(text: 'Suggestions'),
              Tab(text: 'Following'),
              Tab(text: 'Followers'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildUserList(context, 'suggestions', currentUser, _userSearchController.text),
                _buildUserList(context, 'following', currentUser, _userSearchController.text),
                _buildUserList(context, 'followers', currentUser, _userSearchController.text),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(BuildContext context, String type, User currentUser, String searchQuery) {
    // Load minimal user lists instead of streaming the entire collection
    final usersCollection =
        FirebaseFirestore.instance.collection(FirestorePaths.users());
    return StreamBuilder<DocumentSnapshot>(
      stream: usersCollection.doc(currentUser.uid).snapshots(),
      builder: (context, currentUserSnap) {
        if (!currentUserSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final currentData = currentUserSnap.data!.data() as Map<String, dynamic>? ?? {};
        final List<String> myFollowing = List<String>.from(currentData['following'] ?? []);
        final List<String> myFollowers = List<String>.from(currentData['followers'] ?? []);

        // Determine which user IDs to query based on the tab type
        List<String> targetIds;
        switch (type) {
          case 'following':
            targetIds = myFollowing;
            break;
          case 'followers':
            targetIds = myFollowers;
            break;
          default:
            // Suggestions: pick a limited set of recent users; filter later
            targetIds = [];
        }

        if (type == 'suggestions') {
          // Query a limited number of users and filter out self and people already followed
          return FutureBuilder<QuerySnapshot>(
            future: usersCollection.orderBy('createdAt', descending: true).limit(30).get(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              List<DocumentSnapshot> docs = snap.data!.docs;
              docs = docs.where((doc) => doc.id != currentUser.uid && !myFollowing.contains(doc.id)).toList();
              if (searchQuery.isNotEmpty) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['displayName'] ?? '').toLowerCase().contains(searchQuery.toLowerCase());
                }).toList();
              }
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No users found in this category.'),
                      const SizedBox(height: 16),
                      FoutaButton(
                        label: 'Refresh',
                        onPressed: () => setState(() {}),
                      ),
                    ],
                  ),
                );
              }
              return _buildUserListView(docs, myFollowing, context, currentUser);
            },
          );
        } else {
          if (targetIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No users found in this category.'),
                  const SizedBox(height: 16),
                  FoutaButton(
                    label: 'Refresh',
                    onPressed: () => setState(() {}),
                  ),
                ],
              ),
            );
          }
          // Firestore whereIn supports up to 10 elements; chunk if necessary
          final List<Future<QuerySnapshot>> futures = [];
          const chunkSize = 10;
          for (var i = 0; i < targetIds.length; i += chunkSize) {
            final chunk = targetIds.sublist(i, i + chunkSize > targetIds.length ? targetIds.length : i + chunkSize);
            futures.add(usersCollection.where(FieldPath.documentId, whereIn: chunk).get());
          }
          return FutureBuilder<List<QuerySnapshot>>(
            future: Future.wait(futures),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              List<DocumentSnapshot> docs = snap.data!.expand((q) => q.docs).toList();
              if (searchQuery.isNotEmpty) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['displayName'] ?? '').toLowerCase().contains(searchQuery.toLowerCase());
                }).toList();
              }
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No users found in this category.'),
                      const SizedBox(height: 16),
                      FoutaButton(
                        label: 'Refresh',
                        onPressed: () => setState(() {}),
                      ),
                    ],
                  ),
                );
              }
              return _buildUserListView(docs, myFollowing, context, currentUser);
            },
          );
        }
      },
    );
  }

  // Builds the ListView for a list of user documents
  Widget _buildUserListView(List<DocumentSnapshot> users, List<String> myFollowing, BuildContext context, User currentUser) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final userDoc = users[index];
        final userData = userDoc.data() as Map<String, dynamic>;
        final bool isFollowing = myFollowing.contains(userDoc.id);
        return FoutaCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: userDoc.id))),
              child: CircleAvatar(
                backgroundImage: (userData['profileImageUrl'] != null && userData['profileImageUrl']!.toString().isNotEmpty)
                    ? CachedNetworkImageProvider(userData['profileImageUrl'])
                    : null,
                child: (userData['profileImageUrl'] == null || userData['profileImageUrl']!.toString().isEmpty)
                    ? const Icon(Icons.person)
                    : null,
              ),
            ),
            title: Text(userData['displayName'] ?? 'Unknown'),
            subtitle: Text(userData['bio'] ?? '', maxLines: 1),
            trailing: ElevatedButton(
              onPressed: () => _toggleFollow(currentUser.uid, userDoc.id, isFollowing),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: Text(isFollowing ? 'Unfollow' : 'Follow'),
            ),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: userDoc.id))),
          ),
        );
      },
    );
  }
}