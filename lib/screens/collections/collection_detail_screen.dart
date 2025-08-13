import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/collections_service.dart';

/// Displays posts saved in a collection.
class CollectionDetailScreen extends StatelessWidget {
  final String collectionId;
  final String collectionName;
  final String? overrideUid;

  const CollectionDetailScreen({
    super.key,
    required this.collectionId,
    required this.collectionName,
    this.overrideUid,
  });

  @override
  Widget build(BuildContext context) {
    final uid = overrideUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }
    final service = CollectionsService();
    return Scaffold(
      appBar: AppBar(title: Text(collectionName)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users/$uid/collections/$collectionId/items')
            .orderBy('addedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No saved posts'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final postId = docs[index].id;
              return ListTile(
                title: Text('Post $postId'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => service.removeFromCollection(uid, collectionId, postId),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
