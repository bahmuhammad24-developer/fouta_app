// lib/screens/events_list_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/main.dart';
import 'package:fouta_app/screens/create_event_screen.dart';
import 'package:fouta_app/screens/event_details_screen.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Handled by root navigator
          // FIX: Title removed to prevent duplication with the main SliverAppBar
          bottom: const TabBar(
            tabs: [
              Tab(text: 'For You'),
              Tab(text: 'My Events'),
              Tab(text: 'Browse'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildEventsList(context, _getForYouQuery()),
            _buildEventsList(context, _getMyEventsQuery()),
            _buildEventsList(context, _getBrowseQuery()),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'createEventFab',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateEventScreen()),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Query _getForYouQuery() {
    // Placeholder for a real algorithm. For now, just shows all upcoming events.
    return FirebaseFirestore.instance
        .collection('artifacts/$APP_ID/public/data/events')
        .where('eventDate', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('eventDate', descending: false);
  }

  Query _getMyEventsQuery() {
    return FirebaseFirestore.instance
        .collection('artifacts/$APP_ID/public/data/events')
        .where('attendees', arrayContains: currentUser?.uid ?? '')
        .orderBy('eventDate', descending: false);
  }

  Query _getBrowseQuery() {
    return FirebaseFirestore.instance
        .collection('artifacts/$APP_ID/public/data/events')
        .orderBy('eventDate', descending: false);
  }

  Widget _buildEventsList(BuildContext context, Query query) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No events found.'));
        }
        final events = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final eventData = events[index].data() as Map<String, dynamic>;
            return _EventCard(
              eventId: events[index].id,
              eventData: eventData,
            );
          },
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.eventId,
    required this.eventData,
  });

  final String eventId;
  final Map<String, dynamic> eventData;

  @override
  Widget build(BuildContext context) {
    final eventDate = (eventData['eventDate'] as Timestamp).toDate();
    final now = DateTime.now();
    final isPast = eventDate.isBefore(now);
    final String headerImageUrl = eventData['headerImageUrl'] ?? '';
    final List<dynamic> attendees = eventData['attendees'] ?? [];

    return Opacity(
      opacity: isPast ? 0.6 : 1.0,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailsScreen(eventId: eventId),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (headerImageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: headerImageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 140,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => _buildDefaultHeader(context),
                )
              else
                _buildDefaultHeader(context),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEE, MMM d, yyyy • hh:mm a').format(eventDate),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      eventData['title'] ?? 'Untitled Event',
                      style: Theme.of(context).textTheme.headlineSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            eventData['location'] ?? 'No location provided',
                            style: TextStyle(color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${attendees.length} going',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultHeader(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Icon(
        Icons.event,
        size: 60,
        color: Theme.of(context).primaryColor.withOpacity(0.5),
      ),
    );
  }
}