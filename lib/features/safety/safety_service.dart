import 'package:cloud_firestore/cloud_firestore.dart';

/// Stores and evaluates per-user safety settings such as account privacy,
/// reply limits, and block/mute lists.
class SafetyService {
  SafetyService({
    FirebaseFirestore? firestore,
    required this.appId,
    required this.userId,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String appId;
  final String userId;

  DocumentReference<Map<String, dynamic>> get _ref => _firestore.doc(
      'artifacts/$appId/public/data/users/$userId/safety/settings');

  /// Fetches the current user's safety settings.
  Future<Map<String, dynamic>> fetchSettings() async {
    final snap = await _ref.get();
    final data = snap.data() ?? {};
    return {
      'isPrivate': data['isPrivate'] ?? false,
      'limitReplies': data['limitReplies'] ?? 'everyone',
      'mutedUserIds': List<String>.from(data['mutedUserIds'] ?? []),
      'blockedUserIds': List<String>.from(data['blockedUserIds'] ?? []),
    };
  }

  Future<void> updatePrivacy({bool? isPrivate, String? limitReplies}) async {
    final payload = <String, dynamic>{};
    if (isPrivate != null) payload['isPrivate'] = isPrivate;
    if (limitReplies != null) payload['limitReplies'] = limitReplies;
    if (payload.isNotEmpty) {
      await _ref.set(payload, SetOptions(merge: true));
    }
  }

  Future<List<String>> getMutedUserIds() async {
    final data = await fetchSettings();
    return List<String>.from(data['mutedUserIds'] ?? []);
  }

  Future<void> muteUser(String targetId) async {
    await _ref.set({
      'mutedUserIds': FieldValue.arrayUnion([targetId]),
    }, SetOptions(merge: true));
  }

  Future<void> unmuteUser(String targetId) async {
    await _ref.set({
      'mutedUserIds': FieldValue.arrayRemove([targetId]),
    }, SetOptions(merge: true));
  }

  Future<bool> isMuted(String userId) async {
    final ids = await getMutedUserIds();
    return ids.contains(userId);
  }

  Future<List<String>> getBlockedUserIds() async {
    final data = await fetchSettings();
    return List<String>.from(data['blockedUserIds'] ?? []);
  }

  Future<void> blockUser(String targetId) async {
    await _ref.set({
      'blockedUserIds': FieldValue.arrayUnion([targetId]),
    }, SetOptions(merge: true));
  }

  Future<void> unblockUser(String targetId) async {
    await _ref.set({
      'blockedUserIds': FieldValue.arrayRemove([targetId]),
    }, SetOptions(merge: true));
  }

  Future<bool> isBlocked(String userId) async {
    final ids = await getBlockedUserIds();
    return ids.contains(userId);
  }

  /// Checks if [viewerId] may reply to [authorId]'s content.
  Future<bool> canReply({
    required String authorId,
    required String viewerId,
  }) async {
    final authorRef = _firestore
        .doc('artifacts/$appId/public/data/users/$authorId/safety/settings');
    final authorSettings = (await authorRef.get()).data() ?? {};
    final blocked = List<String>.from(authorSettings['blockedUserIds'] ?? []);
    if (blocked.contains(viewerId)) return false;

    final limit = authorSettings['limitReplies'] ?? 'everyone';
    if (limit == 'none') return false;
    if (limit == 'followers') {
      final followersSnap = await _firestore
          .doc('artifacts/$appId/public/data/users/$authorId')
          .get();
      final followers = List<String>.from(followersSnap.data()?['followers'] ?? []);
      if (!followers.contains(viewerId)) return false;
    }

    final viewerRef = _firestore
        .doc('artifacts/$appId/public/data/users/$viewerId/safety/settings');
    final viewerSettings = (await viewerRef.get()).data() ?? {};
    final viewerBlocks =
        List<String>.from(viewerSettings['blockedUserIds'] ?? []);
    if (viewerBlocks.contains(authorId)) return false;

    return true;
  }
}
