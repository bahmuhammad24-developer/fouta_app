// lib/widgets/stories_tray.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fouta_app/main.dart';
import 'package:fouta_app/models/story_model.dart';
import 'package:fouta_app/screens/story_creation_screen.dart';
import 'package:fouta_app/screens/story_camera_screen.dart';
import 'package:fouta_app/screens/story_viewer_screen.dart';

class StoriesTray extends StatelessWidget {
  const StoriesTray({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Container(
      height: 100.0,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('artifacts/$APP_ID/public/data/stories')
            // Order by lastUpdated so the newest stories appear first. We'll filter
            // out expired stories on the client because some documents may not
            // have an `expiresAt` field (e.g. older data). Filtering client‑side
            // prevents unintentionally excluding those records.
            .orderBy('lastUpdated', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: SizedBox.shrink());
          }
          // Filter out any expired stories. Stories missing `expiresAt` are included.
          final originalDocs = snapshot.data!.docs;
          final List<QueryDocumentSnapshot> filteredDocs = originalDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final expiresAt = data['expiresAt'];
            if (expiresAt == null) return true;
            try {
              final ts = expiresAt as Timestamp;
              return ts.toDate().isAfter(DateTime.now());
            } catch (_) {
              return true;
            }
          }).toList();
          // Separate docs into unseen and seen based on whether the current user UID
          // appears in the 'viewedBy' array. Unseen stories should be shown first.
          final List<QueryDocumentSnapshot> unseenDocs = [];
          final List<QueryDocumentSnapshot> seenDocs = [];
          for (final doc in filteredDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final List<dynamic> viewedBy = data['viewedBy'] ?? [];
            final bool hasUnseen = currentUser != null
                ? !viewedBy.contains(currentUser!.uid)
                : true;
            if (hasUnseen) {
              unseenDocs.add(doc);
            } else {
              seenDocs.add(doc);
            }
          }
          final List<QueryDocumentSnapshot> sortedDocs = [...unseenDocs, ...seenDocs];

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            itemCount: sortedDocs.length + 1, // +1 for the "Your Story" button
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildYourStoryAvatar(context, currentUser);
              }
              final storyDoc = sortedDocs[index - 1];
              final storyData = storyDoc.data() as Map<String, dynamic>;

              // Determine if the current user has unseen stories by checking the 'viewedBy' array on the story document
              final List<dynamic> viewedBy = storyData['viewedBy'] ?? [];
              final bool hasUnseen = currentUser != null
                  ? !(viewedBy.contains(currentUser.uid))
                  : true;

              return _StoryAvatar(
                imageUrl: storyData['authorImageUrl'],
                userName: storyData['authorName'],
                hasUnseen: hasUnseen,
                onTap: () {
                  // Build the list of Story models preserving the same order as sortedDocs.
                  final stories = sortedDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Story(
                      userId: doc.id,
                      userName: data['authorName'] ?? 'User',
                      userImageUrl: data['authorImageUrl'] ?? '',
                      slides: [],
                    );
                  }).toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoryViewerScreen(
                        stories: stories,
                        initialStoryIndex: index - 1,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildYourStoryAvatar(BuildContext context, User? currentUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: () {
          // Navigate to the camera interface for capturing a new story.
          Navigator.push(context, MaterialPageRoute(builder: (_) => const StoryCameraScreen()));
        },
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CircleAvatar(
                  radius: 32.0,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white, size: 32),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2.0),
            // FIX: Explicitly constrain height to prevent overflow
            SizedBox(
              height: 14,
              child: Text(
                'Your Story', 
                style: const TextStyle(fontSize: 11),
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final String imageUrl;
  final String userName;
  final bool hasUnseen;
  final VoidCallback onTap;

  const _StoryAvatar({
    required this.imageUrl,
    required this.userName,
    required this.hasUnseen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasUnseen ? Theme.of(context).colorScheme.secondary : Colors.grey,
                  width: 2.0,
                ),
              ),
              child: CircleAvatar(
                radius: 30.0,
                backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                child: imageUrl.isEmpty ? const Icon(Icons.person) : null,
              ),
            ),
            const SizedBox(height: 2.0),
            // FIX: Explicitly constrain height to prevent overflow
            SizedBox(
              height: 14,
              width: 64,
              child: Text(
                userName, 
                style: const TextStyle(fontSize: 11),
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}