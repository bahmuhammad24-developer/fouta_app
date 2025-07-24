// lib/screens/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fouta_app/main.dart'; // Import APP_ID
import 'package:fouta_app/widgets/post_card_widget.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    setState(() {
      _message = msg;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: msg.contains('successful') ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('artifacts/$APP_ID/public/data/posts')
            .doc(widget.postId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Post not found.'));
          }

          final post = snapshot.data!.data() as Map<String, dynamic>;
          final postId = snapshot.data!.id;

          return Column(
            children: [
              if (_message != null)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  color: _message!.contains('successful') ? Colors.green[100] : Colors.red[100],
                  child: Center(
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: _message!.contains('successful') ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: PostCardWidget(
                    key: ValueKey(postId),
                    post: post,
                    postId: postId,
                    currentUser: currentUser,
                    appId: APP_ID,
                    onMessage: _showMessage,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
