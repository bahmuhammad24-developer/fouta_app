// lib/screens/group_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/main.dart';
import 'package:fouta_app/screens/chat_screen.dart';
import 'package:fouta_app/utils/snackbar.dart';

class GroupSetupScreen extends StatefulWidget {
  final List<String> memberIds;
  const GroupSetupScreen({super.key, required this.memberIds});

  @override
  State<GroupSetupScreen> createState() => _GroupSetupScreenState();
}

class _GroupSetupScreenState extends State<GroupSetupScreen> {
  final _groupNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      AppSnackBar.show(context, 'Group name cannot be empty.', isError: true);
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    final List<String> allMemberIds = [currentUser.uid, ...widget.memberIds];

    try {
      final newChatDoc = await FirebaseFirestore.instance
          .collection('artifacts/$APP_ID/public/data/chats')
          .add({
        'participants': allMemberIds,
        'isGroupChat': true,
        'groupName': groupName,
        'groupImageUrl': '',
        'admins': [currentUser.uid],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': 'Group created.',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'unreadCounts': { for (var id in allMemberIds) id : 0 },
      });

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: newChatDoc.id,
            ),
          ),
          (Route<dynamic> route) => route.isFirst,
        );
      }

    } on FirebaseException catch (e) {
      AppSnackBar.show(context, 'Failed to create group: ${e.message}',
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.group_add, size: 50),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'Enter a name for your group',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const Spacer(),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _createGroup,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Create Group'),
              ),
          ],
        ),
      ),
    );
  }
}