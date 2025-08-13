import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/events/events_service.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  final EventsService service;
  final String currentUserId;

  EventDetailScreen({
    Key? key,
    required this.event,
    EventsService? service,
    String? currentUserId,
  })  : service = service ?? EventsService(),
        currentUserId =
            currentUserId ?? FirebaseAuth.instance.currentUser?.uid ?? '',
        super(key: key);

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late List<String> _going;
  late List<String> _interested;

  String get _status {
    if (_going.contains(widget.currentUserId)) return 'going';
    if (_interested.contains(widget.currentUserId)) return 'interested';
    return 'declined';
  }

  @override
  void initState() {
    super.initState();
    _going = List<String>.from(widget.event.attendingIds);
    _interested = List<String>.from(widget.event.interestedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.event.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.event.coverUrl != null &&
                widget.event.coverUrl!.isNotEmpty)
              Image.network(
                widget.event.coverUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 8),
            Text('${_going.length} going • ${_interested.length} interested'),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _setStatus('going'),
                  child: const Text('Going'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _setStatus('interested'),
                  child: const Text('Interested'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _setStatus('declined'),
                  child: const Text('Decline'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(widget.event.description ?? ''),
            const Spacer(),
            const Text('Contact/Host info coming soon'),
          ],
        ),
      ),
    );
  }

  Future<void> _setStatus(String status) async {
    await widget.service.rsvp(widget.event.id, widget.currentUserId, status);
    setState(() {
      _going.remove(widget.currentUserId);
      _interested.remove(widget.currentUserId);
      if (status == 'going') {
        _going.add(widget.currentUserId);
      } else if (status == 'interested') {
        _interested.add(widget.currentUserId);
      }
    });
  }
}
