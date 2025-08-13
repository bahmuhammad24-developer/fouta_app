import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/firestore_paths.dart';

/// Service encapsulating post interactions such as reposting and quoting.
class PostService {
  PostService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _posts = (firestore ?? FirebaseFirestore.instance)
            .collection(FirestorePaths.posts());

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final CollectionReference<Map<String, dynamic>> _posts;

  /// Create a simple repost of [originPostId].
  Future<void> repost(String originPostId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final original = await _posts.doc(originPostId).get();
    if (!original.exists) return;
    final data = original.data()!;
    final sharerDoc = await _firestore
        .collection(FirestorePaths.users())
        .doc(user.uid)
        .get();
    final displayName = sharerDoc.data()?['displayName']?.toString() ?? 'Anonymous';
    await _posts.add({
      'type': 'repost',
      'originPostId': originPostId,
      'originAuthorId': data['authorId'],
      'originAuthorDisplayName': data['authorDisplayName'],
      'originContent': data['content'],
      'originMediaUrl': data['mediaUrl'],
      'originMediaType': data['mediaType'],
      'authorId': user.uid,
      'authorDisplayName': displayName,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': [],
      'shares': 0,
      'bookmarks': [],
      'calculatedEngagement': 0,
    });
    await _posts.doc(originPostId).update({'shares': FieldValue.increment(1)});
  }

  /// Share [originPostId] with additional [quoteText].
  Future<void> quotePost(String originPostId, String quoteText) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final original = await _posts.doc(originPostId).get();
    if (!original.exists) return;
    final data = original.data()!;
    final sharerDoc = await _firestore
        .collection(FirestorePaths.users())
        .doc(user.uid)
        .get();
    final displayName = sharerDoc.data()?['displayName']?.toString() ?? 'Anonymous';
    await _posts.add({
      'type': 'quote',
      'originPostId': originPostId,
      'originAuthorId': data['authorId'],
      'originAuthorDisplayName': data['authorDisplayName'],
      'originContent': data['content'],
      'originMediaUrl': data['mediaUrl'],
      'originMediaType': data['mediaType'],
      'quoteText': quoteText.isNotEmpty ? quoteText : null,
      'authorId': user.uid,
      'authorDisplayName': displayName,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': [],
      'shares': 0,
      'bookmarks': [],
      'calculatedEngagement': 0,
    });
    await _posts.doc(originPostId).update({'shares': FieldValue.increment(1)});
  }
}
