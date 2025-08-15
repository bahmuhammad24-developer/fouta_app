import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/features/marketplace/marketplace_service.dart';

void main() {
  test('Product alias getters map to canonical fields', () {
    final p = Product(
      id: '1',
      title: 'Alias Test',
      priceAmount: 12.34,
      priceCurrency: 'USD',
      sellerId: 'u1',
      imageUris: [Uri.parse('https://example.com/img.png')],
      favoriteUserIds: const ['u1'],
    );
    expect(p.price, 12.34);
    expect(p.currency, 'USD');
    expect(p.urls.first, 'https://example.com/img.png');
    expect(p.favoriteUserIds.contains('u1'), true);
  });
}
