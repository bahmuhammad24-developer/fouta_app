import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/main.dart';
import 'package:fouta_app/utils/json_safety.dart' as safe;
import 'package:fouta_app/utils/firestore_paths.dart';

/// Service for creating and querying stories.
class StoriesService {
  final FirebaseFirestore _firestore;

  StoriesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.stories());

  /// Create a new story document and return its id.
  Future<String> createStory({
    required String userId,
    required String mediaUrl,
    required String mediaType,
    double? aspectRatio,
    List<Map<String, dynamic>> overlays = const [],
  }) async {
    final now = DateTime.now();
    final doc = _collection.doc();
    await doc.set({
      'authorId': userId,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      if (aspectRatio != null) 'aspectRatio': aspectRatio,
      'overlays': overlays,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
      'viewerIds': <String>[],
    });
    return doc.id;
  }

  /// Stream stories for a user and their following if available.
  Stream<List<Map<String, dynamic>>> streamStoriesForUser(String userId) async* {
    final userDoc = await _firestore
        .collection(FirestorePaths.users())
        .doc(userId)
        .get();
    final following = safe.asStringList(userDoc.data()?['following']);
    final authors = [userId, ...following];

    yield* _collection
        .where('authorId', whereIn: authors)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'authorId': data['authorId']?.toString() ?? '',
          'mediaUrl': data['mediaUrl']?.toString() ?? '',
          'mediaType': data['mediaType']?.toString() ?? '',
          'aspectRatio': safe.asDoubleOrNull(data['aspectRatio']),
          'overlays': safe.asListOf<Map<String, dynamic>>(data['overlays']),
          'createdAt':
              (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ?? '',
          'expiresAt':
              (data['expiresAt'] as Timestamp?)?.toDate().toIso8601String() ?? '',
          'viewerIds': safe.asStringList(data['viewerIds']),
        };
      }).toList();
    });
  }

  /// Mark a story as viewed by a user.
  Future<void> markViewed({
    required String storyId,
    required String userId,
  }) {
    return _collection.doc(storyId).update({
      'viewerIds': FieldValue.arrayUnion([userId]),
    });
  }
}

