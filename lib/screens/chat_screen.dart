// lib/screens/chat_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fouta_app/screens/chat_details_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:fouta_app/main.dart'; // Import APP_ID
import 'package:fouta_app/screens/profile_screen.dart';
import 'package:fouta_app/widgets/chat_video_player.dart';
import 'package:fouta_app/widgets/full_screen_image_viewer.dart';

class ChatScreen extends StatefulWidget {
  final String? chatId;
  final String? otherUserId;
  final String? otherUserName;

  const ChatScreen({super.key, this.chatId, this.otherUserId, this.otherUserName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  String? _currentChatId;
  DocumentReference? _chatRef;

  XFile? _selectedMediaFile;
  Uint8List? _selectedMediaBytes;
  String _mediaType = '';
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  Timer? _typingTimer;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentChatId = widget.chatId;
    if (_currentChatId == null) {
      _findOrCreateChat();
    } else {
      _ensureChatDataAndRead();
    }
     _messageController.addListener(_handleTyping);
  }

  Future<void> _findOrCreateChat() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || widget.otherUserId == null) return;
    
    final participants = [currentUser.uid, widget.otherUserId!]..sort();
    final chatId = participants.join('_');
    _chatRef = FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/chats').doc(chatId);

    if(mounted) {
      setState(() {
        _currentChatId = chatId;
      });
    }

    final doc = await _chatRef!.get();
    if (!doc.exists) {
      await _chatRef!.set({
        'participants': participants,
        'isGroupChat': false,
        'admins': [],
        'createdAt': FieldValue.serverTimestamp(),
        'unreadCounts': {
          currentUser.uid: 0,
          widget.otherUserId!: 0,
        },
        'typingStatus': {},
      });
    }
    _markChatAsRead();
  }
  
  Future<void> _ensureChatDataAndRead() async {
    if (_currentChatId == null) return;
    _chatRef = FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/chats').doc(_currentChatId!);
    final doc = await _chatRef!.get();

    // DATA MIGRATION: If old chat is missing new fields, add them.
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>; // FIX: Cast data to Map
      Map<String, dynamic> updates = {};
      if (!data.containsKey('isGroupChat')) updates['isGroupChat'] = false;
      if (!data.containsKey('admins')) updates['admins'] = [];
      if (!data.containsKey('typingStatus')) updates['typingStatus'] = {};
      
      if(updates.isNotEmpty) await _chatRef!.update(updates);
    }
    _markChatAsRead();
  }

  Future<void> _markChatAsRead() async {
    if (_currentChatId == null) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    await _chatRef?.update({
      'unreadCounts.${currentUser.uid}': 0,
    });
  }
  
  void _handleTyping() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _chatRef == null) return;

    if (_typingTimer?.isActive ?? false) _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
       _chatRef?.update({'typingStatus.${currentUser.uid}': false});
    });
    _chatRef?.update({'typingStatus.${currentUser.uid}': true});
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleTyping);
    _messageController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickMediaForChat(ImageSource source, {bool isVideo = false}) async {
    if (_isUploading) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload in progress...')));
      return;
    }

    XFile? pickedFile;
    try {
      pickedFile = isVideo 
        ? await _picker.pickVideo(source: source)
        : await _picker.pickImage(source: source);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking media: $e')));
    }

    if(pickedFile != null) {
      setState(() {
        _selectedMediaFile = pickedFile;
        _mediaType = isVideo ? 'video' : 'image';
        if (kIsWeb) {
          pickedFile!.readAsBytes().then((bytes) {
            setState(() {
              _selectedMediaBytes = bytes;
            });
          });
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty && _selectedMediaFile == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _currentChatId == null) return;
    
    String? mediaUrl;
    if (_selectedMediaFile != null) {
      setState(() => _isUploading = true);
      final ref = FirebaseStorage.instance.ref().child('chat_media/$_currentChatId/${DateTime.now().millisecondsSinceEpoch}');
      
      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(await _selectedMediaFile!.readAsBytes());
      } else {
        uploadTask = ref.putFile(File(_selectedMediaFile!.path));
      }

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if(mounted) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
      });

      mediaUrl = await (await uploadTask).ref.getDownloadURL();
      if(mounted) setState(() => _isUploading = false);
    }

    final userDoc = await FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(currentUser.uid).get();
    final senderName = userDoc.data()?['displayName'] ?? 'Anonymous';

    await _chatRef!
        .collection('messages')
        .add({
          'senderId': currentUser.uid,
          'senderName': senderName,
          'content': messageText,
          'mediaUrl': mediaUrl,
          'mediaType': _mediaType,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false, // Kept for simplicity, but new `readBy` is primary
          'readBy': [currentUser.uid],
          'reactions': {},
          'isReply': false,
        });

    await _chatRef!.update({
          'lastMessage': messageText.isNotEmpty ? messageText : 'Sent a $_mediaType',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'typingStatus.${currentUser.uid}': false,
        });

    _messageController.clear();
    if(mounted) {
      setState(() {
        _selectedMediaFile = null;
        _selectedMediaBytes = null;
        _mediaType = '';
      });
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('HH:mm').format(timestamp.toDate());
  }

  Widget _buildChatMediaDisplay(String mediaType, String mediaUrl) {
    switch (mediaType) {
      case 'image':
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageViewer(imageUrl: mediaUrl))),
          child: CachedNetworkImage(
            imageUrl: mediaUrl,
            placeholder: (context, url) => Container(
              width: 150, height: 150,
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            width: 150, height: 150, fit: BoxFit.cover,
          ),
        );
      case 'video':
        return SizedBox(width: 150, child: ChatVideoPlayer(videoUrl: mediaUrl));
      default:
        return const SizedBox.shrink();
    }
  }
  
  // NOTE: This is a placeholder for a more complex reaction UI
  Widget _buildReactions(Map<String, dynamic> reactions) {
    if (reactions.isEmpty) return const SizedBox.shrink();
    // In a real app, this would be a row of styled emoji counts
    return Text("Reactions: ${reactions.length}", style: const TextStyle(fontSize: 10, color: Colors.grey));
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe, bool isGroupChat) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).colorScheme.primary : Colors.grey[300],
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (isGroupChat && !isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  message['senderName'] ?? 'User',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 12),
                ),
              ),
            // Placeholder for Reply UI
            if (message['isReply'] == true)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Text("Replying to: ${message['replyToContent'] ?? ''}", style: const TextStyle(fontSize: 12)),
              ),
            if(message['mediaUrl'] != null && message['mediaUrl']!.isNotEmpty)
              _buildChatMediaDisplay(message['mediaType'] ?? '', message['mediaUrl']),
            if(message['content'] != null && message['content']!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  message['content'],
                  style: TextStyle(color: isMe ? Colors.white : Colors.black),
                ),
              ),
            _buildReactions(message['reactions'] ?? {}),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          if (_isUploading) LinearProgressIndicator(value: _uploadProgress),
          if (_selectedMediaFile != null) 
            SizedBox(
              height: 100,
              child: Stack(
                children: [
                  kIsWeb && _selectedMediaBytes != null
                    ? Image.memory(_selectedMediaBytes!, height: 100, width: 100, fit: BoxFit.cover)
                    : !kIsWeb 
                      ? Image.file(File(_selectedMediaFile!.path), height: 100, width: 100, fit: BoxFit.cover)
                      : Container(),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white)),
                      onPressed: () => setState(() {
                        _selectedMediaFile = null;
                        _selectedMediaBytes = null;
                      }),
                    ),
                  )
                ],
              ),
            ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.image), onPressed: () => _pickMediaForChat(ImageSource.gallery)),
              IconButton(icon: const Icon(Icons.videocam), onPressed: () => _pickMediaForChat(ImageSource.gallery, isVideo: true)),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(hintText: 'Type a message...'),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: _currentChatId == null 
          ? Text(widget.otherUserName ?? 'New Chat')
          : StreamBuilder<DocumentSnapshot>(
          stream: _chatRef?.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              // FIX: Use the passed name as a fallback while loading
              return Text(widget.otherUserName ?? 'Loading...');
            }
            
            final chatData = snapshot.data!.data() as Map<String, dynamic>;
            final bool isGroup = chatData['isGroupChat'] ?? false;
            
            if(isGroup) {
              return Text(chatData['groupName'] ?? 'Group Chat');
            } else {
              // If we already have the name, use it. Otherwise, fetch it.
              if (widget.otherUserName != null) {
                return Text(widget.otherUserName!);
              }
              final otherUserId = (chatData['participants'] as List).firstWhere((id) => id != currentUser!.uid, orElse: () => '');
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if(!userSnapshot.hasData) return const Text('Chat');
                  return Text(userSnapshot.data!['displayName'] ?? 'Chat');
                }
              );
            }
          }
        ),
        actions: [
          if (_currentChatId != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatDetailsScreen(chatId: _currentChatId!)),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _currentChatId == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<QuerySnapshot>(
              stream: _chatRef
                  ?.collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Say hello!'));
                }
                
                final messages = snapshot.data!.docs;
                final chatDocFuture = _chatRef!.get();

                return FutureBuilder<DocumentSnapshot>(
                  future: chatDocFuture,
                  builder: (context, chatSnapshot) {
                    if(!chatSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final isGroupChat = chatSnapshot.data!.data() != null && (chatSnapshot.data!.data() as Map<String, dynamic>)['isGroupChat'] == true;

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(8.0),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index].data() as Map<String, dynamic>;
                        final bool isMe = message['senderId'] == currentUser?.uid;

                        return _buildMessageBubble(message, isMe, isGroupChat);
                      },
                    );
                  }
                );
              },
            ),
          ),
          // Placeholder for Typing Indicator
          _buildMessageComposer(),
        ],
      ),
    );
  }
}