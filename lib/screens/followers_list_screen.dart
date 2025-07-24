// lib/screens/followers_list_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/main.dart';
import 'package:fouta_app/screens/profile_screen.dart';

class FollowersListScreen extends StatelessWidget {
  final String title;
  final List<String> userIds;

  const FollowersListScreen({
    super.key,
    required this.title,
    required this.userIds,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: userIds.isEmpty
          ? const Center(child: Text('No users to display.'))
          : ListView.builder(
              itemCount: userIds.length,
              itemBuilder: (context, index) {
                final userId = userIds[index];
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(userId).get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const ListTile(title: Text('Loading...'));
                    }
                    final userData = snapshot.data!.data() as Map<String, dynamic>;
                    final userName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
                    final profileImageUrl = userData['profileImageUrl'] as String? ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: profileImageUrl.isNotEmpty ? CachedNetworkImageProvider(profileImageUrl) : null,
                        child: profileImageUrl.isEmpty ? const Icon(Icons.person) : null,
                      ),
                      title: Text(userName),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}