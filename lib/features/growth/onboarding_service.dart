import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles onboarding interest selection for new users.
class OnboardingService {
  OnboardingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Stores the chosen [interests] for the user with [userId].
  Future<void> saveInterests(String userId, List<String> interests) async {
    await _firestore.collection('users').doc(userId).set({
      'interests': interests,
      'onboardedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _log('Saved interests for $userId');
  }

  /// Returns a default feed descriptor when onboarding is skipped. This is a
  /// simple placeholder for a location and language weighted popular feed.
  Map<String, String> defaultFeed(String locale, String location) {
    _log('Provided default feed for $locale/$location');
    return {'locale': locale, 'location': location};
  }

  void _log(String message) {
    final now = DateTime.now().toIso8601String();
    // ignore: avoid_print
    print('[$now][OnboardingService] $message');
  }
}
