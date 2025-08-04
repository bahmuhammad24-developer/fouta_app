// lib/screens/event_details_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/main.dart';
import 'package:fouta_app/screens/edit_event_screen.dart';
import 'package:fouta_app/screens/event_invite_screen.dart';
import 'package:fouta_app/screens/profile_screen.dart';
import 'package:fouta_app/widgets/fouta_button.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();

  Future<void> _toggleRsvp(List<dynamic> attendees) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final eventRef = FirebaseFirestore.instance
        .collection('artifacts/$APP_ID/public/data/events')
        .doc(widget.eventId);

    if (attendees.contains(currentUser.uid)) {
      await eventRef.update({
        'attendees': FieldValue.arrayRemove([currentUser.uid])
      });
    } else {
      await eventRef.update({
        'attendees': FieldValue.arrayUnion([currentUser.uid])
      });
    }
  }
  
  Future<void> _addComment() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final String commentText = _commentController.text.trim();
    if(currentUser == null || commentText.isEmpty) return;
    
    final userDoc = await FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(currentUser.uid).get();
    
    await FirebaseFirestore.instance
      .collection('artifacts/$APP_ID/public/data/events')
      .doc(widget.eventId)
      .collection('comments')
      .add({
        'content': commentText,
        'authorId': currentUser.uid,
        'authorDisplayName': userDoc.data()?['displayName'] ?? 'Anonymous',
        'authorProfileImageUrl': userDoc.data()?['profileImageUrl'] ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
      FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('artifacts/$APP_ID/public/data/events')
          .doc(widget.eventId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text('Event not found.')));
        }

        final event = snapshot.data!.data() as Map<String, dynamic>;
        final eventDate = (event['eventDate'] as Timestamp).toDate();
        final List<dynamic> attendees = event['attendees'] ?? [];
        final List<dynamic> invited = event['invitedIds'] ?? [];
        final bool isCreator = currentUser != null && event['creatorId'] == currentUser.uid;
        final bool isRsvpd = currentUser != null && attendees.contains(currentUser.uid);
        final String headerImageUrl = event['headerImageUrl'] ?? '';

        return Scaffold(
          // Move edit button into the app bar actions to avoid overlaying the comment field
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220.0,
                pinned: true,
                actions: [
                  if (isCreator)
                    IconButton(
                      tooltip: 'Edit Event',
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditEventScreen(
                              eventId: widget.eventId,
                              initialData: event,
                            ),
                          ),
                        );
                      },
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: headerImageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: headerImageUrl,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Theme.of(context).primaryColor,
                          child: Icon(
                            Icons.event,
                            size: 80,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  // FIX: All event info moved into a Card below the AppBar
                  Card(
                    margin: const EdgeInsets.all(16.0),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['title'] ?? 'Event Details',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoTile(
                            Icons.calendar_today,
                            DateFormat('EEEE, MMMM d, yyyy').format(eventDate),
                          ),
                          _buildInfoTile(
                            Icons.access_time,
                            DateFormat('hh:mm a').format(eventDate),
                          ),
                          _buildInfoTile(
                            Icons.location_on,
                            event['location'] ?? 'No location provided',
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
                            onPressed: () => _toggleRsvp(attendees),
                            icon: Icon(isRsvpd ? Icons.cancel : Icons.check_circle_outline),
                            label: Text(isRsvpd ? 'Cancel RSVP' : 'RSVP'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isRsvpd ? Colors.grey : Theme.of(context).colorScheme.secondary,
                              minimumSize: const Size.fromHeight(50),
                            ),
                          ),
                          const Divider(height: 32),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invited (${invited.length})',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              _buildInvitedList(invited, isCreator),
                              const Divider(height: 32),
                            ],
                          ),
                          // Attendees section
                          Text(
                            'Who\'s Going (${attendees.length})',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          _buildAttendeesList(attendees),
                          const Divider(height: 32),
                          Text(
                            'Discussions',
                             style: Theme.of(context).textTheme.titleLarge,
                          ),
                          _buildCommentsSection(),
                        ],
                      ),
                    ),
                  )
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildAttendeesList(List<dynamic> attendees) {
    if (attendees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Be the first to RSVP!'),
            const SizedBox(height: 16),
            FoutaButton(
              label: 'RSVP',
              onPressed: () => _toggleRsvp(attendees),
            ),
          ],
        ),
      );
    }
    return SizedBox(
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
                        child: profileImageUrl.isEmpty ? const Icon(Icons.person) : null,
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
    );
  }

  // Build a horizontal list of invited users similar to attendees. Users can see who is invited but not yet attending.
  Widget _buildInvitedList(List<dynamic> invited, bool isCreator) {
    if (invited.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No one invited yet.'),
            if (isCreator) ...[
              const SizedBox(height: 16),
              FoutaButton(
                label: 'Invite People',
                onPressed: () async {
                  final selected = await Navigator.push<List<String>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventInviteScreen(
                        initialSelected: invited.cast<String>(),
                      ),
                    ),
                  );
                  if (selected != null) {
                    await FirebaseFirestore.instance
                        .collection('artifacts/$APP_ID/public/data/events')
                        .doc(widget.eventId)
                        .update({'invitedIds': selected});
                  }
                },
              ),
            ],
          ],
        ),
      );
    }
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: invited.length,
        itemBuilder: (context, index) {
          final userId = invited[index];
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
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: profileImageUrl.isNotEmpty
                          ? CachedNetworkImageProvider(profileImageUrl)
                          : null,
                      child: profileImageUrl.isEmpty ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userData['firstName'] ?? 'User',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('artifacts/$APP_ID/public/data/events')
              .doc(widget.eventId)
              .collection('comments')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if(!snapshot.hasData) return const SizedBox.shrink();
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final comment = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage: (comment['authorProfileImageUrl'] != null && comment['authorProfileImageUrl'].isNotEmpty)
                      ? CachedNetworkImageProvider(comment['authorProfileImageUrl'])
                      : null,
                  ),
                  title: Text(comment['authorDisplayName'] ?? 'User'),
                  subtitle: Text(comment['content'] ?? ''),
                );
              },
            );
          },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commentController,
          decoration: InputDecoration(
            hintText: 'Add a comment...',
            suffixIcon: IconButton(
              icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
              onPressed: _addComment,
            ),
          ),
        ),
      ],
    );
  }
}