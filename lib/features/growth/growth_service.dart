/// Manages onboarding flows, referrals, and social graph import.
import 'dart:async';

import 'package:uuid/uuid.dart';

class GrowthService {
  final _referralCodes = <String, String>{}; // code -> userId
  final Set<String> _syncedContacts = {};
  final Map<String, List<String>> _interests = {};
  final Uuid _uuid = const Uuid();

  /// Generates a unique referral code for [userId].
  String createReferralCode(String userId) {
    final code = _uuid.v4();
    _referralCodes[code] = userId;
    _log('Created referral for $userId');
    return code;
  }

  /// Returns the userId associated with a referral [code], if any.
  String? redeemReferralCode(String code) {
    final uid = _referralCodes[code];
    _log('Redeemed $code -> $uid');
    return uid;
  }

  /// Syncs [contacts] with the service and returns the ones that are newly
  /// discovered. The sync is simulated with a short delay.
  Future<List<String>> syncContacts(List<String> contacts) async {
    final newContacts = contacts.where((c) => _syncedContacts.add(c)).toList();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _log('Synced ${newContacts.length} contacts');
    return newContacts;
  }

  /// Stores the onboarding [interests] selected by [userId].
  void recordInterests(String userId, List<String> interests) {
    _interests[userId] = interests;
    _log('Recorded interests for $userId');
  }

  void _log(String message) {
    final now = DateTime.now().toIso8601String();
    // ignore: avoid_print
    print('[$now][GrowthService] $message');
  }
}
