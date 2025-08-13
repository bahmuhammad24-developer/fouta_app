/// Handles profile mutations like updates, creator mode toggling and pinned posts.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/firestore_paths.dart';

class ProfileService {
  ProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  List<String> sanitizeLinks(List<String> links) {
    final regex = RegExp(r'^https?://');
    return links.where((l) => regex.hasMatch(l)).toList();
  }

  Future<void> toggleCreatorMode(String uid, bool isCreator) async {
    await _firestore
        .collection(FirestorePaths.users())
        .doc(uid)
        .set({'isCreator': isCreator}, SetOptions(merge: true));
  }

  Future<void> updateProfile(
    String uid, {
    String? displayName,
    String? bio,
    List<String>? links,
    String? location,
    String? pronouns,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['displayName'] = displayName;
    if (bio != null) data['bio'] = bio;
    if (links != null) data['links'] = sanitizeLinks(links);
    if (location != null) data['location'] = location;
    if (pronouns != null) data['pronouns'] = pronouns;
    await _firestore
        .collection(FirestorePaths.users())
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  Future<void> pinPost(String uid, String postId) async {
    await _firestore
        .collection(FirestorePaths.users())
        .doc(uid)
        .set({'pinnedPostId': postId}, SetOptions(merge: true));
  }

  Future<void> unpinPost(String uid) async {
    await _firestore
        .collection(FirestorePaths.users())
        .doc(uid)
        .set({'pinnedPostId': FieldValue.delete()}, SetOptions(merge: true));
  }
}
