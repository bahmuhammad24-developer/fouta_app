// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fouta_app/main.dart';
import 'package:fouta_app/screens/post_detail_screen.dart';
import 'package:fouta_app/screens/profile_screen.dart';
import 'package:fouta_app/screens/create_post_screen.dart';
import 'package:fouta_app/utils/date_utils.dart';
import 'package:fouta_app/widgets/fouta_button.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    return DateUtilsHelper.formatRelative(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please log in to see notifications.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('artifacts/$APP_ID/public/data/users')
            .doc(currentUser.uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No notifications yet.'),
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
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              final String type = notification['type'] ?? '';
              final String fromUserName = notification['fromUserName'] ?? 'Someone';
              final String content = notification['content'] ?? '';
              final Timestamp? timestamp = notification['timestamp'];

              IconData iconData;
              Color iconColor;
              switch (type) {
                case 'like':
                  iconData = Icons.favorite;
                  iconColor = Colors.red;
                  break;
                case 'comment':
                  iconData = Icons.comment;
                  iconColor = Colors.blue;
                  break;
                case 'follow':
                  iconData = Icons.person_add;
                  iconColor = Colors.green;
                  break;
                default:
                  iconData = Icons.notifications;
                  iconColor = Colors.grey;
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: iconColor,
                  child: Icon(iconData, color: Colors.white),
                ),
                title: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: fromUserName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: ' $content'),
                    ],
                  ),
                ),
                subtitle: Text(
                  _formatTimestamp(timestamp),
                ),
                onTap: () {
                  final String? postId = notification['postId'];
                  final String? fromUserId = notification['fromUserId'];
                  // FIX: Added parentheses to correct the logical condition
                  if ((type == 'like' || type == 'comment') && postId != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId)));
                  } else if (type == 'follow' && fromUserId != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: fromUserId)));
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
