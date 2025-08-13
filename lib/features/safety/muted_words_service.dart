import 'package:cloud_firestore/cloud_firestore.dart';

/// Manages per-user muted words.
class MutedWordsService {
  MutedWordsService({
    FirebaseFirestore? firestore,
    required this.appId,
    required this.userId,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String appId;
  final String userId;

  DocumentReference<Map<String, dynamic>> get _ref => _firestore
      .doc('artifacts/$appId/public/data/users/$userId/safety/muted_words');

  Future<List<String>> getMutedWords() async {
    final snap = await _ref.get();
    return List<String>.from(snap.data()?['words'] ?? []);
  }

  Future<void> addWord(String word) async {
    final w = word.trim().toLowerCase();
    if (w.isEmpty) return;
    await _ref.set({
      'words': FieldValue.arrayUnion([w]),
    }, SetOptions(merge: true));
  }

  Future<void> removeWord(String word) async {
    final w = word.trim().toLowerCase();
    await _ref.set({
      'words': FieldValue.arrayRemove([w]),
    }, SetOptions(merge: true));
  }

  Future<bool> shouldHide(String text) async {
    final words = await getMutedWords();
    final lower = text.toLowerCase();
    return words.any((w) => lower.contains(w));
  }
}
