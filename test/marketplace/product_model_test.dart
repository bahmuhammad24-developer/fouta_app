import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/features/marketplace/marketplace_service.dart';

void main() {
  test('Product serialization roundtrip keeps price fields', () {
    final p = Product(
      id: 'p1',
      title: 'Lamp',
      priceAmount: 19.5,
      priceCurrency: 'USD',
      sellerId: 'u1',
      description: 'Desk lamp',
    );

    final map = p.toMap();
    final p2 = Product.fromMap('p1', map);

    expect(p2.priceAmount, 19.5);
    expect(p2.priceCurrency, 'USD');
    expect(p2.title, 'Lamp');
  });
}

