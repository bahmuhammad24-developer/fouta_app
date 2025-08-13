import '../models/message.dart';

/// Returns true if any user other than [currentUserId] is typing.
bool otherUsersTyping(Iterable<String> typingUserIds, String currentUserId) {
  return typingUserIds.any((id) => id != currentUserId);
}

/// Derives a [MessageStatus] based on the `readAt` map of a message.
MessageStatus statusFromReadAt(Map<String, dynamic>? readAt, String currentUserId) {
  final others = readAt?.keys.where((id) => id != currentUserId) ?? Iterable.empty();
  return others.isNotEmpty ? MessageStatus.read : MessageStatus.sent;
}
