// lib/screens/add_members_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/main.dart';

class AddMembersScreen extends StatefulWidget {
  final String chatId;
  final List<String> currentMemberIds;

  const AddMembersScreen({
    super.key,
    required this.chatId,
    required this.currentMemberIds,
  });

  @override
  State<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<AddMembersScreen> {
  List<String> _selectedMemberIds = [];
  List<Map<String, dynamic>> _eligibleFollowers = [];
  bool _isLoading = true;
  bool _hasFollowers = true;

  @override
  void initState() {
    super.initState();
    _fetchEligibleFollowers();
  }

  Future<void> _fetchEligibleFollowers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('artifacts/$APP_ID/public/data/users')
        .doc(currentUser.uid)
        .get();

    if (userDoc.exists) {
      final List<String> followingIds =
          List<String>.from(userDoc.data()?['following'] ?? []);
      _hasFollowers = followingIds.isNotEmpty;

      if (_hasFollowers) {
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('artifacts/$APP_ID/public/data/users')
            .where(FieldPath.documentId, whereIn: followingIds)
            .get();

        setState(() {
          _eligibleFollowers = usersSnapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .where(
                  (user) => !widget.currentMemberIds.contains(user['id']))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _eligibleFollowers = [];
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _eligibleFollowers = [];
        _hasFollowers = false;
        _isLoading = false;
      });
    }
  }

  void _onMemberSelected(bool? isSelected, String userId) {
    setState(() {
      if (isSelected == true) {
        _selectedMemberIds.add(userId);
      } else {
        _selectedMemberIds.remove(userId);
      }
    });
  }

  Future<void> _addSelectedMembers() async {
    if (_selectedMemberIds.isEmpty) {
      Navigator.pop(context);
      return;
    }
    // Prepare updates for participants and unread counts
    final Map<String, dynamic> updates = {
      'participants': FieldValue.arrayUnion(_selectedMemberIds),
    };
    for (final id in _selectedMemberIds) {
      updates['unreadCounts.$id'] = 0;
    }

    await FirebaseFirestore.instance
        .collection('artifacts/$APP_ID/public/data/chats')
        .doc(widget.chatId)
        .update(updates);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Members'),
        actions: [
          TextButton(
            onPressed: _addSelectedMembers,
            child: const Text('Done'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _eligibleFollowers.isEmpty
              ? Center(
                  child: Text(_hasFollowers
                      ? 'All your followers are already in this group.'
                      : 'You need to follow users to add them to a group.'),
                )
              : ListView.builder(
                  itemCount: _eligibleFollowers.length,
                  itemBuilder: (context, index) {
                    final user = _eligibleFollowers[index];
                    final isSelected = _selectedMemberIds.contains(user['id']);

                    return CheckboxListTile(
                      secondary: CircleAvatar(
                        backgroundImage: (user['profileImageUrl'] != null && user['profileImageUrl']!.isNotEmpty)
                            ? NetworkImage(user['profileImageUrl'])
                            : null,
                        child: (user['profileImageUrl'] == null || user['profileImageUrl']!.isEmpty)
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(user['displayName'] ?? 'Unknown User'),
                      value: isSelected,
                      onChanged: (bool? value) {
                        _onMemberSelected(value, user['id']);
                      },
                    );
                  },
                ),
    );
  }
}