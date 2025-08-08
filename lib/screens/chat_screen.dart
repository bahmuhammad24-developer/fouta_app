// lib/screens/chat_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fouta_app/services/connectivity_provider.dart';
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
import 'package:media_kit/media_kit.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:fouta_app/services/connectivity_provider.dart';
import 'package:fouta_app/widgets/chat_audio_player.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

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

  // The `record` package updated its API, replacing the concrete `Record`
  // class with the new `AudioRecorder` implementation. The previous `Record`
  // class is now abstract, so instantiating it directly caused compilation
  // errors. `AudioRecorder` provides the same recording features with an
  // updated `start` signature that accepts a [RecordConfig].
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecordingAudio = false;

  Timer? _typingTimer;

  final ImagePicker _picker = ImagePicker();

  // Reaction & reply state
  DocumentSnapshot? _replyingToMessage;

  // Reaction emoji options to present to the user on long‑press
  static const List<String> _reactionOptions = ['❤️', '😂', '👍', '😮', '😢', '🙏'];

  // Media upload limitations
  // Increase limits so typical smartphone videos can be shared.
  static const int _maxVideoFileSize = 500 * 1024 * 1024; // 500 MB
  static const int _maxVideoDurationSeconds = 300; // 5 minutes max

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
      // Fetch participant details for denormalization
      final usersCollection = FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users');
      final currentUserDoc = await usersCollection.doc(currentUser.uid).get();
      final otherUserDoc = await usersCollection.doc(widget.otherUserId!).get();
      final currentUserData = currentUserDoc.data() ?? {};
      final otherUserData = otherUserDoc.data() ?? {};
      final participantDetails = {
        currentUser.uid: {
          'displayName': currentUserData['displayName'] ?? 'User',
          'profileImageUrl': currentUserData['profileImageUrl'] ?? '',
        },
        widget.otherUserId!: {
          'displayName': otherUserData['displayName'] ?? 'User',
          'profileImageUrl': otherUserData['profileImageUrl'] ?? '',
        },
      };
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
        'participantDetails': participantDetails,
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

      // If participantDetails are missing (legacy chats), populate them
      if (!data.containsKey('participantDetails') && data['isGroupChat'] == false) {
        final participants = List<String>.from(data['participants'] ?? []);
        if (participants.length == 2) {
          final usersCollection = FirebaseFirestore.instance.collection('artifacts/$APP_ID/public/data/users');
          final details = <String, Map<String, dynamic>>{};
          for (final uid in participants) {
            final userDoc = await usersCollection.doc(uid).get();
            final userData = userDoc.data() ?? {};
            details[uid] = {
              'displayName': userData['displayName'] ?? 'User',
              'profileImageUrl': userData['profileImageUrl'] ?? '',
            };
          }
          updates['participantDetails'] = details;
        }
      }
      
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

    if (pickedFile != null) {
      // Validate video constraints for non-web platforms
      if (isVideo && !kIsWeb) {
        final fileSize = File(pickedFile.path).lengthSync();
        if (fileSize > _maxVideoFileSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video is too large. Please select a video under 500 MB.')),
          );
          return;
        }
        final player = Player();
        // Open without autoplay so the selected video's audio doesn't play in the background.
        await player.open(Media(pickedFile.path), play: false);
        final duration = player.state.duration;
        if (duration.inSeconds > _maxVideoDurationSeconds) {
          await player.dispose();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video is too long. Please select a video under 5 minutes.')),
          );
          return;
        }
        await player.dispose();
      }

      setState(() {
        _selectedMediaFile = pickedFile;
        _mediaType = isVideo ? 'video' : 'image';
        if (kIsWeb && !isVideo) {
          // Only read bytes for image previews on web. Video previews show a placeholder.
          pickedFile!.readAsBytes().then((bytes) {
            setState(() {
              _selectedMediaBytes = bytes;
            });
          });
        } else {
          _selectedMediaBytes = null;
        }
      });
    }
  }

    Future<void> _startRecording() async {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          const RecordConfig(),
          path: path,
        );
        if (mounted) {
          setState(() => _isRecordingAudio = true);
        }
      }
    }

    Future<void> _stopRecording() async {
      final path = await _audioRecorder.stop();
      if (mounted) {
        setState(() => _isRecordingAudio = false);
      }
      if (path != null) {
        setState(() {
          _selectedMediaFile = XFile(path);
          _mediaType = 'audio';
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
      // Prevent media uploads while offline. Text messages will still be queued via Firestore offline persistence.
      final connectivity = context.read<ConnectivityProvider>();
      if (!connectivity.isOnline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are offline. Cannot send media in chat.')),
        );
        return;
      }
      setState(() => _isUploading = true);
      final ext = _selectedMediaFile!.name.split('.').last;
      final ref = FirebaseStorage.instance.ref().child(
          'chat_media/$_currentChatId/${DateTime.now().millisecondsSinceEpoch}.$ext');

      Uint8List? bytesToUpload;
      File? fileToUpload;
      if (kIsWeb) {
        bytesToUpload = await _selectedMediaFile!.readAsBytes();
      } else {
        if (_mediaType == 'image') {
          final originalBytes = await _selectedMediaFile!.readAsBytes();
          final img.Image? decoded = img.decodeImage(originalBytes);
          if (decoded != null) {
            final compressed = img.encodeJpg(decoded, quality: 80);
            bytesToUpload = Uint8List.fromList(compressed);
          } else {
            fileToUpload = File(_selectedMediaFile!.path);
          }
        } else {
          fileToUpload = File(_selectedMediaFile!.path);
        }
      }

      final metadata = SettableMetadata(
        contentType: _mediaType == 'video'
            ? 'video/mp4'
            : _mediaType == 'audio'
                ? 'audio/mpeg'
                : 'image/jpeg',
      );

      UploadTask uploadTask;
      if (bytesToUpload != null) {
        uploadTask = ref.putData(bytesToUpload, metadata);
      } else if (fileToUpload != null) {
        uploadTask = ref.putFile(fileToUpload, metadata);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid media data for upload.')),
        );
        setState(() => _isUploading = false);
        return;
      }

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (mounted) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
      });

      mediaUrl = await (await uploadTask).ref.getDownloadURL();
      if (mounted) setState(() => _isUploading = false);
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
          // Reply metadata
          'isReply': _replyingToMessage != null,
          // If replying, include reference data of the original message
          if (_replyingToMessage != null) ...{
            'replyToMessageId': _replyingToMessage!.id,
            'replyToContent': _replyingToMessage!.data() != null
                ? (_replyingToMessage!.data()! as Map<String, dynamic>)['content'] ?? ''
                : '',
            'replyToSenderName': _replyingToMessage!.data() != null
                ? (_replyingToMessage!.data()! as Map<String, dynamic>)['senderName'] ?? ''
                : '',
          },
        });

    await _chatRef!.update({
          'lastMessage': messageText.isNotEmpty
              ? messageText
              : _mediaType == 'audio'
                  ? 'Sent a voice message'
                  : 'Sent a $_mediaType',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'typingStatus.${currentUser.uid}': false,
        });

    _messageController.clear();
    if(mounted) {
      setState(() {
        _selectedMediaFile = null;
        _selectedMediaBytes = null;
        _mediaType = '';
        // Clear reply state after sending
        _replyingToMessage = null;
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
      case 'audio':
        return SizedBox(width: 150, child: ChatAudioPlayer(source: mediaUrl));
      default:
        return const SizedBox.shrink();
    }
  }
  
  // NOTE: This is a placeholder for a more complex reaction UI
  Widget _buildReactions(Map<String, dynamic> reactions) {
    if (reactions.isEmpty) return const SizedBox.shrink();
    final List<Widget> reactionWidgets = [];
    reactions.forEach((emoji, users) {
      if (users is List && users.isNotEmpty) {
        final bool reactedByMe = users.contains(FirebaseAuth.instance.currentUser?.uid);
        reactionWidgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            margin: const EdgeInsets.only(right: 4, top: 4),
            decoration: BoxDecoration(
              color: reactedByMe ? Colors.blueGrey[50] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 2),
                Text(
                  users.length.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white54
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });
    return Wrap(children: reactionWidgets);
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe, bool isGroupChat) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primary
              : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700]
                  : Colors.grey[300]),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white54
                        : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ),
            // Placeholder for Reply UI
            if (message['isReply'] == true)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message['replyToSenderName'] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white54
                            : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if ((message['replyToContent'] ?? '').toString().isNotEmpty)
                      Text(
                        message['replyToContent'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white54
                              : Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
            if(message['mediaUrl'] != null && message['mediaUrl']!.isNotEmpty)
              _buildChatMediaDisplay(message['mediaType'] ?? '', message['mediaUrl']),
            if(message['content'] != null && message['content']!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  message['content'],
                  style: TextStyle(
                    color: isMe
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                  ),
                ),
              ),
            _buildReactions(message['reactions'] ?? {}),
          ],
        ),
      ),
    );
  }

  // Show a bottom sheet with reaction options and a reply action when a message is long‑pressed.
  void _showReactionReplySheet(DocumentSnapshot messageDoc) {
    final messageData = messageDoc.data() as Map<String, dynamic>;
    final String messageId = messageDoc.id;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _reactionOptions.map((emoji) {
                    return IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _toggleReaction(messageId, emoji, messageData);
                      },
                      icon: Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    );
                  }).toList(),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.reply),
                  title: const Text('Reply'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _replyingToMessage = messageDoc;
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Toggle reaction for a message. Adds or removes the current user's UID in the reactions[emoji] list.
  Future<void> _toggleReaction(String messageId, String emoji, Map<String, dynamic> messageData) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _chatRef == null) return;
    final String uid = currentUser.uid;
    final Map<String, dynamic> reactions = Map<String, dynamic>.from(messageData['reactions'] ?? {});
    final List<dynamic> usersForEmoji = reactions[emoji] != null ? List<dynamic>.from(reactions[emoji]) : [];
    final bool userReacted = usersForEmoji.contains(uid);
    final DocumentReference messageRef = _chatRef!.collection('messages').doc(messageId);
    if (!userReacted) {
      // Add reaction
      await messageRef.update({
        'reactions.$emoji': FieldValue.arrayUnion([uid])
      });
    } else {
      // Remove reaction
      await messageRef.update({
        'reactions.$emoji': FieldValue.arrayRemove([uid])
      });
    }
  }

  Widget _buildMessageComposer() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // If replying to a message, show preview
          if (_replyingToMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (_replyingToMessage!.data()! as Map<String, dynamic>)['senderName'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white54
                                : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (_replyingToMessage!.data()! as Map<String, dynamic>)['content'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white54
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      setState(() {
                        _replyingToMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          if (_isUploading) LinearProgressIndicator(value: _uploadProgress),
          if (_selectedMediaFile != null && _mediaType == 'audio')
            SizedBox(
              height: 60,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ChatAudioPlayer(source: _selectedMediaFile!.path, isLocal: true),
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white)),
                      onPressed: () => setState(() {
                        _selectedMediaFile = null;
                        _mediaType = '';
                      }),
                    ),
                  )
                ],
              ),
            )
          else if (_selectedMediaFile != null)
            SizedBox(
              height: 100,
              child: Stack(
                children: [
                  if (_mediaType == 'video')
                    Container(
                      width: 100,
                      height: 100,
                      color: Colors.black,
                      child: const Center(
                        child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
                      ),
                    )
                  else
                    (kIsWeb && _selectedMediaBytes != null
                        ? Image.memory(_selectedMediaBytes!, height: 100, width: 100, fit: BoxFit.cover)
                        : !kIsWeb
                            ? Image.file(File(_selectedMediaFile!.path), height: 100, width: 100, fit: BoxFit.cover)
                            : Container()),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white)),
                      onPressed: () => setState(() {
                        _selectedMediaFile = null;
                        _selectedMediaBytes = null;
                        _mediaType = '';
                      }),
                    ),
                  )
                ],
              ),
            ),
          Row(
            children: [
              GestureDetector(
                onLongPressStart: (_) => _startRecording(),
                onLongPressEnd: (_) => _stopRecording(),
                child: Icon(
                  Icons.mic,
                  color: _isRecordingAudio ? Colors.red : null,
                ),
              ),
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
                        final messageDoc = messages[index];
                        final message = messageDoc.data() as Map<String, dynamic>;
                        final bool isMe = message['senderId'] == currentUser?.uid;
                        final messageWidget = _buildMessageBubble(message, isMe, isGroupChat);
                        return GestureDetector(
                          onLongPress: () {
                            _showReactionReplySheet(messageDoc);
                          },
                          child: messageWidget,
                        );
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