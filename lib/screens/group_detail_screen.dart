import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/groups/groups_service.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({
    super.key,
    required this.group,
    GroupsService? service,
    String? currentUserId,
  })  : service = service ?? GroupsService(),
        currentUserId =
            currentUserId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  final Group group;
  final GroupsService service;
  final String currentUserId;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late List<String> _memberIds;

  bool get _isMember => _memberIds.contains(widget.currentUserId);

  @override
  void initState() {
    super.initState();
    _memberIds = List<String>.from(widget.group.memberIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.group.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.group.coverUrl != null &&
              widget.group.coverUrl!.isNotEmpty)
            Image.network(
              widget.group.coverUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.group.description != null)
                  Text(widget.group.description!),
                const SizedBox(height: 8),
                Text('Members: ${_memberIds.length}'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _toggleMembership,
                  child: Text(_isMember ? 'Leave' : 'Join'),
                ),
              ],
            ),
          ),
          const Divider(),
          const Expanded(
            child: Center(child: Text('Group posts coming soon')),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMembership() async {
    if (_isMember) {
      await widget.service.leaveGroup(widget.group.id, widget.currentUserId);
      setState(() {
        _memberIds.remove(widget.currentUserId);
      });
    } else {
      await widget.service.joinGroup(widget.group.id, widget.currentUserId);
      setState(() {
        _memberIds.add(widget.currentUserId);
      });
    }
  }
}
