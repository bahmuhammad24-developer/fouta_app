import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/main.dart';

/// Screen that allows users to select people they follow to invite to an event.
/// Returns a List<String> of selected user IDs when popped.
class EventInviteScreen extends StatefulWidget {
  final List<String> initialSelected;
  const EventInviteScreen({super.key, this.initialSelected = const []});

  @override
  State<EventInviteScreen> createState() => _EventInviteScreenState();
}

class _EventInviteScreenState extends State<EventInviteScreen> {
  List<String> _selectedIds = [];
  List<Map<String, dynamic>> _followingUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedIds = List<String>.from(widget.initialSelected);
    _fetchFollowing();
  }

  Future<void> _fetchFollowing() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('artifacts/$APP_ID/public/data/users')
          .doc(currentUser.uid)
          .get();
      final List<dynamic> followingIds = userDoc.data()?['following'] ?? [];
      if (followingIds.isNotEmpty) {
        // Batch whereIn queries into chunks of 10 to avoid Firestore limitations
        final List<List<dynamic>> chunks = [];
        for (var i = 0; i < followingIds.length; i += 10) {
          chunks.add(followingIds.sublist(i, i + 10 > followingIds.length ? followingIds.length : i + 10));
        }
        final List<Map<String, dynamic>> users = [];
        for (final chunk in chunks) {
          final snap = await FirebaseFirestore.instance
              .collection('artifacts/$APP_ID/public/data/users')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          users.addAll(snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
        }
        setState(() {
          _followingUsers = users;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onToggleSelected(String userId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedIds.add(userId);
      } else {
        _selectedIds.remove(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite People'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedIds);
            },
            child: Text('Done', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _followingUsers.isEmpty
              ? const Center(child: Text('You are not following anyone.'))
              : ListView.builder(
                  itemCount: _followingUsers.length,
                  itemBuilder: (context, index) {
                    final user = _followingUsers[index];
                    final bool isSelected = _selectedIds.contains(user['id']);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (bool? value) {
                        _onToggleSelected(user['id'], value ?? false);
                      },
                      title: Text(user['displayName'] ?? 'User'),
                      secondary: CircleAvatar(
                        backgroundImage: (user['profileImageUrl'] != null && user['profileImageUrl'].isNotEmpty)
                            ? NetworkImage(user['profileImageUrl'])
                            : null,
                        child: (user['profileImageUrl'] == null || user['profileImageUrl'].isEmpty)
                            ? const Icon(Icons.person)
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}