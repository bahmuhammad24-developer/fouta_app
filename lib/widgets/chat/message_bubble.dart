// lib/widgets/chat/message_bubble.dart

import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../models/media_item.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onRetry;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = isMe
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceVariant;
    final textColor = isMe
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.replyToMessageId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Replying to ${message.replyToMessageId}',
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ),
            if (message.text != null)
              Text(
                message.text!,
                style: TextStyle(color: textColor),
              ),
            if (message.attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: message.attachments
                      .map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AttachmentView(attachment: a),
                          ))
                      .toList(),
                ),
              ),
            if (message.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  children: message.reactions.entries
                      .map((e) => Text(
                            '${e.key} ${e.value.length}',
                            style:
                                TextStyle(color: textColor, fontSize: 12),
                          ))
                      .toList(),
                ),
              ),
            Align(
              alignment: Alignment.bottomRight,
              child: _StatusIndicator(
                status: message.status,
                onRetry: onRetry,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentView extends StatelessWidget {
  final MediaItem attachment;

  const _AttachmentView({required this.attachment});

  @override
  Widget build(BuildContext context) {
    if (attachment.type == MediaType.image) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          attachment.url,
          height: 150,
          width: 150,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      height: 150,
      width: 150,
      color: Colors.black26,
      child: const Icon(Icons.play_arrow),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final MessageStatus status;
  final VoidCallback? onRetry;
  final Color color;

  const _StatusIndicator(
      {required this.status, this.onRetry, required this.color});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color? iconColor = color;
    switch (status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        iconColor = color.withOpacity(0.7);
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        iconColor = color.withOpacity(0.7);
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        iconColor = color.withOpacity(0.7);
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        break;
      case MessageStatus.failed:
        icon = Icons.error;
        iconColor = Theme.of(context).colorScheme.error;
        if (onRetry != null) {
          return GestureDetector(
            onTap: onRetry,
            child: Icon(icon, color: iconColor, size: 16),
          );
        }
        break;
    }
    return Icon(icon, color: iconColor, size: 16);
  }
}
