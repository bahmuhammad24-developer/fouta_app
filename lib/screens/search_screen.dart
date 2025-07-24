// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/main.dart';
import 'package:fouta_app/screens/profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Search for users...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!.docs.where((doc) {
            final userData = doc.data() as Map<String, dynamic>;
            final fullName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.toLowerCase();
            return fullName.contains(_searchQuery);
          }).toList();

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userData = user.data() as Map<String, dynamic>;
              final userName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
              final profileImageUrl = userData['profileImageUrl'] as String? ?? '';

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
                  child: profileImageUrl.isEmpty ? const Icon(Icons.person) : null,
                ),
                title: Text(userName),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.id)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
