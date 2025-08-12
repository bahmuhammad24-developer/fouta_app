import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/features/growth/growth_service.dart';

void main() {
  test('referral code generation and redemption', () {
    final service = GrowthService();
    final code = service.createReferralCode('user1');
    expect(service.redeemReferralCode(code), 'user1');
  });

  test('syncContacts returns only new contacts', () async {
    final service = GrowthService();
    final first = await service.syncContacts(['a', 'b']);
    final second = await service.syncContacts(['b', 'c']);
    expect(first, ['a', 'b']);
    expect(second, ['c']);
  });
}
