import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/features/monetization/monetization_service.dart';

void main() {
  test('purchase records product', () async {
    final service = MonetizationService();
    final result = await service.purchase('pro');
    expect(result, true);
    expect(service.hasPurchased('pro'), true);
  });

  test('additional monetization methods record purchases', () async {
    final service = MonetizationService();
    await service.purchaseProduct('item1');
    await service.subscribeToCreator('creator');
    await service.tipCreator('creator', 100);
    expect(service.hasPurchased('item1'), true);
    expect(service.hasPurchased('sub-creator'), true);
    expect(service.hasPurchased('tip-creator-100'), true);
  });
}
