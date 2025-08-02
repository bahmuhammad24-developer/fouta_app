// lib/screens/chat_details_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fouta_app/screens/add_members_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/main.dart';
import 'package:fouta_app/screens/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatDetailsScreen extends StatefulWidget {
  final String chatId;

  const ChatDetailsScreen({super.key, required this.chatId});

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late DocumentReference _chatRef;

  @override
  void initState() {
    super.initState();
    _chatRef = FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/chats').doc(widget.chatId);
  }

  Future<void> _removeMember(String memberId) async {
    await _chatRef.update({
      'participants': FieldValue.arrayRemove([memberId])
    });
  }
  
  Future<void> _promoteToAdmin(String memberId) async {
    await _chatRef.update({
      'admins': FieldValue.arrayUnion([memberId])
    });
  }

  Future<void> _leaveGroup() async {
    // Confirmation dialog logic here...
    await _chatRef.update({
      'participants': FieldValue.arrayRemove([_currentUser!.uid])
    });
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
  
  Future<void> _blockUser(String otherUserId) async {
    await FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(_currentUser!.uid).update({
      'blockedUsers': FieldValue.arrayUnion([otherUserId])
    });
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: _chatRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final chatData = snapshot.data!.data() as Map<String, dynamic>;
          final bool isGroupChat = chatData['isGroupChat'] ?? false;
          
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, chatData),
              SliverList(
                delegate: SliverChildListDelegate([
                  _buildBody(context, chatData, isGroupChat),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildSliverAppBar(BuildContext context, Map<String, dynamic> chatData) {
    final bool isGroupChat = chatData['isGroupChat'] ?? false;
    if (isGroupChat) {
      return _buildGroupAppBar(context, chatData);
    } else {
      final otherUserId = (chatData['participants'] as List).firstWhere((id) => id != _currentUser!.uid);
      return _buildOneOnOneAppBar(context, otherUserId);
    }
  }

  SliverAppBar _buildGroupAppBar(BuildContext context, Map<String, dynamic> chatData) {
    final List<dynamic> participants = chatData['participants'] ?? [];
    // Only admins should see the add-member button. Determine if current user is an admin.
    final List<dynamic> admins = chatData['admins'] ?? [];
    final bool amIAdmin = _currentUser != null && admins.contains(_currentUser!.uid);
    return SliverAppBar(
      expandedHeight: 220.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          chatData['groupName'] ?? 'Group Chat',
          style: const TextStyle(color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 8)]),
        ),
        background: SafeArea(
          child: SingleChildScrollView( // FIX: Added SingleChildScrollView to prevent overflow
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    chatData['groupName'] ?? 'Group Chat',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: amIAdmin ? participants.length + 1 : participants.length,
                    itemBuilder: (context, index) {
                      // Show the add button only for admins as the last item
                      if (amIAdmin && index == participants.length) {
                        return _buildAddMemberButton(context, chatData);
                      }
                      return _buildParticipantAvatar(context, participants[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildOneOnOneAppBar(BuildContext context, String userId) {
     return SliverAppBar(
      expandedHeight: 220.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(userId).get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: (userData['profileImageUrl'] != null && userData['profileImageUrl'].isNotEmpty)
                      ? CachedNetworkImageProvider(userData['profileImageUrl'])
                      : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userData['displayName'] ?? 'User',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildParticipantAvatar(BuildContext context, String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(8.0), child: CircleAvatar(radius: 25));
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: (userData['profileImageUrl'] != null && userData['profileImageUrl'].isNotEmpty)
                    ? CachedNetworkImageProvider(userData['profileImageUrl'])
                    : null,
                ),
                const SizedBox(height: 4),
                Text(userData['firstName'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddMemberButton(BuildContext context, Map<String, dynamic> chatData) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          InkWell(
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => AddMembersScreen(
                 chatId: widget.chatId,
                 currentMemberIds: List<String>.from(chatData['participants'] ?? []),
               )));
            },
            child: CircleAvatar(
              radius: 25,
              backgroundColor: scheme.secondary.withOpacity(0.8),
              child: Icon(Icons.add, color: scheme.onSecondary),
            ),
          ),
          const SizedBox(height: 4),
          Text('Add', style: TextStyle(color: scheme.onSecondary, fontSize: 12)),
        ],
      ),
    );
  }
  
  Widget _buildBody(BuildContext context, Map<String, dynamic> chatData, bool isGroupChat) {
    final List<dynamic> participants = chatData['participants'] ?? [];
    final List<dynamic> admins = chatData['admins'] ?? [];
    final bool amIAdmin = _currentUser != null && admins.contains(_currentUser!.uid);
    final otherUserId = isGroupChat ? null : participants.firstWhere((id) => id != _currentUser!.uid);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(isGroupChat) ...[
            Text('Members (${participants.length})', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final userId = participants[index];
                final bool isUserAdmin = admins.contains(userId);
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(userId).get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) return const ListTile();
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(backgroundImage: CachedNetworkImageProvider(userData['profileImageUrl'] ?? '')),
                      title: Text(userData['displayName'] ?? 'User'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isUserAdmin) const Chip(label: Text('Admin')),
                          if (amIAdmin && userId != _currentUser!.uid)
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'remove') _removeMember(userId);
                                if (value == 'promote') _promoteToAdmin(userId);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'remove', child: Text('Remove from Group')),
                                if (!isUserAdmin) const PopupMenuItem(value: 'promote', child: Text('Promote to Admin')),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const Divider(height: 32),
          ],
          
          Text('Settings', style: Theme.of(context).textTheme.titleLarge),
          SwitchListTile(
            title: const Text('Mute Notifications'),
            value: false, // Placeholder
            onChanged: (val) {}, // Placeholder
          ),
          const Divider(height: 32),
          
          // FIX: Renamed from 'Danger Zone' to 'Actions'
          Text('Actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(isGroupChat ? Icons.logout : Icons.block, color: Colors.red),
            title: Text(isGroupChat ? 'Leave Group' : 'Block User', style: const TextStyle(color: Colors.red)),
            onTap: () {
              if (isGroupChat) {
                _leaveGroup();
              } else {
                _blockUser(otherUserId);
              }
            },
          ),
        ],
      ),
    );
  }
}