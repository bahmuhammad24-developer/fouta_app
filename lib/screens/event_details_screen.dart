// lib/screens/event_details_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/main.dart';
import 'package:fouta_app/screens/edit_event_screen.dart';
import 'package:fouta_app/screens/profile_screen.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventDetailsScreen extends StatelessWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  Future<void> _toggleRsvp(String eventId, List<dynamic> attendees, String? currentUserId) async {
    if (currentUserId == null) return;
    
    final eventRef = FirebaseFirestore.instance
        .collection('artifacts/$APP_ID/public/data/events')
        .doc(eventId);

    if (attendees.contains(currentUserId)) {
      // User is already RSVP'd, so remove them
      await eventRef.update({
        'attendees': FieldValue.arrayRemove([currentUserId])
      });
    } else {
      // User is not RSVP'd, so add them
      await eventRef.update({
        'attendees': FieldValue.arrayUnion([currentUserId])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('artifacts/$APP_ID/public/data/events')
                .doc(eventId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox.shrink();
              }
              final event = snapshot.data!.data() as Map<String, dynamic>;
              final isCreator = currentUser != null && event['creatorId'] == currentUser.uid;

              if (isCreator) {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Event',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditEventScreen(
                          eventId: eventId,
                          initialData: event,
                        ),
                      ),
                    );
                  },
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('artifacts/$APP_ID/public/data/events')
            .doc(eventId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Event not found.'));
          }

          final event = snapshot.data!.data() as Map<String, dynamic>;
          final eventDate = (event['eventDate'] as Timestamp).toDate();
          final List<dynamic> attendees = event['attendees'] ?? [];
          final bool isCreator = currentUser != null && event['creatorId'] == currentUser.uid;
          final bool isRsvpd = currentUser != null && attendees.contains(currentUser.uid);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        event['title'] ?? 'Untitled Event',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    if (isCreator)
                      Chip(
                        avatar: Icon(Icons.star, color: Colors.grey[700]),
                        label: const Text('My Event'),
                        backgroundColor: Colors.yellow[100],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(DateFormat('EEEE, MMMM d, yyyy').format(eventDate)),
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(DateFormat('hh:mm a').format(eventDate)),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(event['location'] ?? 'No location provided'),
                ),
                const Divider(height: 32),
                Text(
                  'About this event',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(event['description'] ?? 'No description available.'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _toggleRsvp(eventId, attendees, currentUser?.uid),
                  icon: Icon(isRsvpd ? Icons.cancel : Icons.check_circle_outline),
                  label: Text(isRsvpd ? 'Cancel RSVP' : 'RSVP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRsvpd ? Colors.grey : Theme.of(context).colorScheme.secondary,
                    foregroundColor: isRsvpd ? Colors.white : Colors.black,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                const Divider(height: 32),
                Text(
                  'Attendees (${attendees.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                attendees.isEmpty
                    ? const Center(child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Be the first to RSVP!'),
                    ))
                    : SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: attendees.length,
                          itemBuilder: (context, index) {
                            final userId = attendees[index];
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('artifacts/$APP_ID/public/data/users')
                                  .doc(userId)
                                  .get(),
                              builder: (context, userSnapshot) {
                                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                                  return const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircleAvatar(child: Icon(Icons.person)),
                                  );
                                }
                                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                                final profileImageUrl = userData['profileImageUrl'] as String? ?? '';
                                return GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId))),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 25,
                                          backgroundImage: profileImageUrl.isNotEmpty
                                              ? CachedNetworkImageProvider(profileImageUrl)
                                              : null,
                                          child: profileImageUrl.isEmpty
                                              ? const Icon(Icons.person)
                                              : null,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          userData['firstName'] ?? 'User',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}