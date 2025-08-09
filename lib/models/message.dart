// lib/models/message.dart

import 'media_item.dart';

enum MessageStatus { sending, sent, delivered, read, failed }

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final DateTime createdAt;
  final DateTime? editedAt;
  final String? text;
  final List<MediaItem> attachments;
  final String? replyToMessageId;
  final MessageStatus status;
  final Map<String, Set<String>> reactions;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.createdAt,
    this.editedAt,
    this.text,
    List<MediaItem>? attachments,
    this.replyToMessageId,
    this.status = MessageStatus.sending,
    Map<String, Set<String>>? reactions,
  })  : attachments = attachments ?? const [],
        reactions = reactions ?? {};
}
