/// Manages onboarding flows, referrals, and social graph import.
import 'dart:async';

import 'package:uuid/uuid.dart';

class GrowthService {
  final _referralCodes = <String, String>{}; // code -> userId
  final Set<String> _syncedContacts = {};
  final Uuid _uuid = const Uuid();

  /// Generates a unique referral code for [userId].
  String createReferralCode(String userId) {
    final code = _uuid.v4();
    _referralCodes[code] = userId;
    return code;
  }

  /// Returns the userId associated with a referral [code], if any.
  String? redeemReferralCode(String code) => _referralCodes[code];

  /// Syncs [contacts] with the service and returns the ones that are newly
  /// discovered. The sync is simulated with a short delay.
  Future<List<String>> syncContacts(List<String> contacts) async {
    final newContacts = contacts.where((c) => _syncedContacts.add(c)).toList();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return newContacts;
  }
}
