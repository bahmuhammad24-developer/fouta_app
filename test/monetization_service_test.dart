import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/features/monetization/monetization_service.dart';

void main() {
  test('purchase records product', () async {
    final service = MonetizationService();
    final result = await service.purchase('pro');
    expect(result, true);
    expect(service.hasPurchased('pro'), true);
  });
}
