import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../utils/notification_utils.dart';
import 'post_detail_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';

class NotificationsInboxScreen extends StatefulWidget {
  final FirebaseFirestore? firestore;
  final String? uid;
  const NotificationsInboxScreen({super.key, this.firestore, this.uid});

  @override
  State<NotificationsInboxScreen> createState() => _NotificationsInboxScreenState();
}

class _NotificationsInboxScreenState extends State<NotificationsInboxScreen> {
  final int _pageSize = 20;
  final List<DocumentSnapshot<Map<String, dynamic>>> _items = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _loading = false;
  bool _hasMore = true;
  late final ScrollController _scrollController;
  late final FirebaseFirestore _firestore;
  String? _uid;
  Map<String, bool> _prefs = defaultNotificationPrefs();

  @override
  void initState() {
    super.initState();
    _firestore = widget.firestore ?? FirebaseFirestore.instance;
    _uid = widget.uid ?? FirebaseAuth.instance.currentUser?.uid;
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadPrefs().then((_) => _fetchMore());
  }

  Future<void> _loadPrefs() async {
    if (_uid == null) return;
    final doc = await _firestore
        .collection('artifacts/$APP_ID/public/data/users')
        .doc(_uid)
        .collection('settings')
        .doc('notifications')
        .get();
    final data = doc.data();
    if (data != null) {
      _prefs.addAll(data.map((k, v) => MapEntry(k, v == true)));
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loading &&
        _hasMore) {
      _fetchMore();
    }
  }

  Future<void> _fetchMore() async {
    if (_uid == null || _loading) return;
    _loading = true;
    var query = _firestore
        .collection('artifacts/$APP_ID/public/data/notifications')
        .doc(_uid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(_pageSize);
    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }
    final snap = await query.get();
    final docs = snap.docs;
    final mapped = docs.map((d) => d.data()).toList();
    final filtered = filterNotifications(mapped, _prefs);
    for (final data in filtered) {
      final index = mapped.indexOf(data);
      _items.add(docs[index]);
    }
    if (docs.isNotEmpty) {
      _lastDoc = docs.last;
    }
    _hasMore = docs.length == _pageSize;
    setState(() {
      _loading = false;
    });
  }

  Future<void> _open(DocumentSnapshot<Map<String, dynamic>> doc) async {
    await doc.reference.update({'read': true});
    final data = doc.data();
    final type = data?['type'] as String? ?? '';
    final actorId = data?['actorId'] as String?;
    final postId = data?['postId'] as String?;
    switch (type) {
      case 'follows':
        if (actorId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfileScreen(userId: actorId)),
          );
        }
        break;
      case 'comments':
      case 'likes':
      case 'reposts':
      case 'mentions':
        if (postId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId)),
          );
        }
        break;
      case 'messages':
        if (actorId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen(otherUserId: actorId)),
          );
        }
        break;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please log in to see notifications.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _items.isEmpty
          ? const Center(child: Text('No notifications yet.'))
          : ListView.builder(
              controller: _scrollController,
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final data = _items[index].data();
                final type = data?['type'] as String? ?? '';
                final actorId = data?['actorId'] as String? ?? '';
                return ListTile(
                  title: Text('$type from $actorId'),
                  subtitle: Text('${data?['createdAt'] ?? ''}'),
                  onTap: () => _open(_items[index]),
                );
              },
            ),
    );
  }
}
