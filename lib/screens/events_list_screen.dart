import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/events/events_service.dart';
import 'event_detail_screen.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key, EventsService? service, String? currentUserId})
      : service = service ?? EventsService(),
        currentUserId =
            currentUserId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  final EventsService service;
  final String currentUserId;

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  bool _showMine = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          Row(
            children: [
              const Text('Mine'),
              Switch(
                value: _showMine,
                onChanged: (v) => setState(() => _showMine = v),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Event>>(
        stream: widget.service.streamUpcomingEvents(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var events = snapshot.data!;
          if (_showMine) {
            events = events
                .where((e) => e.ownerId == widget.currentUserId)
                .toList();
          }
          if (events.isEmpty) {
            return const Center(child: Text('No upcoming events'));
          }
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final e = events[index];
              return ListTile(
                title: Text(e.title),
                subtitle: Text('${e.attendingIds.length} going'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventDetailScreen(
                        event: e,
                        service: widget.service,
                        currentUserId: widget.currentUserId,
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
}
