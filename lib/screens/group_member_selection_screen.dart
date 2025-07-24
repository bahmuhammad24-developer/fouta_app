// lib/screens/group_member_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/main.dart';
import 'package:fouta_app/screens/group_setup_screen.dart';

class GroupMemberSelectionScreen extends StatefulWidget {
  const GroupMemberSelectionScreen({super.key});

  @override
  State<GroupMemberSelectionScreen> createState() =>
      _GroupMemberSelectionScreenState();
}

class _GroupMemberSelectionScreenState
    extends State<GroupMemberSelectionScreen> {
  List<String> _selectedMemberIds = [];
  List<Map<String, dynamic>> _followingUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFollowing();
  }

  Future<void> _fetchFollowing() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('artifacts/$APP_ID/public/data/users')
        .doc(currentUser.uid)
        .get();

    if (userDoc.exists) {
      final List<String> followingIds =
          List<String>.from(userDoc.data()?['following'] ?? []);
      
      if (followingIds.isNotEmpty) {
        final usersSnapshot = await FirebaseFirestore.instance
          .collection('artifacts/$APP_ID/public/data/users')
          .where(FieldPath.documentId, whereIn: followingIds)
          .get();
        
        setState(() {
          _followingUsers = usersSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _selectedMemberIds.isNotEmpty
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupSetupScreen(
                          memberIds: _selectedMemberIds,
                        ),
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _followingUsers.isEmpty
              ? const Center(
                  child: Text('You need to follow users to add them to a group.'))
              : ListView.builder(
                  itemCount: _followingUsers.length,
                  itemBuilder: (context, index) {
                    final user = _followingUsers[index];
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