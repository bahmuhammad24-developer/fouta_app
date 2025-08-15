import 'package:cloud_firestore/cloud_firestore.dart';

import '../../main.dart';
import '../../utils/json_safety.dart';

/// Marketplace product domain model.
class Product {
  final String id;
  final String title;
  final double priceAmount; // required by product_detail_screen
  final String priceCurrency; // required by product_detail_screen
  final String? description;
  final List<Uri> imageUris;
  final String sellerId;

  Product({
    required this.id,
    required this.title,
    required this.priceAmount,
    required this.priceCurrency,
    required this.sellerId,
    this.description,
    List<Uri>? imageUris,
  }) : imageUris = imageUris ?? const [];

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      title: (map['title'] ?? '').toString(),
      priceAmount: (map['priceAmount'] is num)
          ? (map['priceAmount'] as num).toDouble()
          : double.tryParse('${map['priceAmount']}') ?? 0.0,
      priceCurrency: (map['priceCurrency'] ?? 'USD').toString(),
      description: (map['description'] as String?)?.trim(),
      imageUris: (map['imageUris'] as List?)
              ?.map((e) => Uri.tryParse(e.toString()))
              .whereType<Uri>()
              .toList() ??
          const [],
      sellerId: (map['sellerId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'priceAmount': priceAmount,
        'priceCurrency': priceCurrency,
        'description': description,
        'imageUris': imageUris.map((u) => u.toString()).toList(),
        'sellerId': sellerId,
      };
}

class MarketplaceService {
  MarketplaceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore
      .collection('artifacts')
      .doc(APP_ID)
      .collection('public')
      .doc('data')
      .collection('products');

  /// Stubbed create product. Replace with Firestore write in a future PR.
  Future<String> createProduct({
    required String title,
    required double priceAmount,
    required String priceCurrency,
    String? description,
    List<Uri>? imageUris,
    required String createdBy,
  }) async {
    // Simulate latency and return a synthetic ID
    await Future.delayed(const Duration(milliseconds: 300));
    return 'stub_prod_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> toggleFavorite(String productId, String userId) async {
    final doc = _collection.doc(productId);
    final snap = await doc.get();
    final favs = asStringList(snap.data()?['favoriteUserIds']);
    final value = favs.contains(userId)
        ? FieldValue.arrayRemove([userId])
        : FieldValue.arrayUnion([userId]);
    await doc.update({'favoriteUserIds': value});
  }
}

extension MarketplaceQueries on MarketplaceService {
  /// TEMP: return a demo product for UI testing until real backend is wired.
  Future<Product> getProductById(String id) async {
    // Replace with Firestore in a later PR
    await Future.delayed(const Duration(milliseconds: 100));
    return Product(
      id: id,
      title: 'Demo Product',
      priceAmount: 49.99,
      priceCurrency: 'USD',
      description: 'A great demo item.',
      imageUris: const [],
      sellerId: 'demo-user',
    );
  }

  /// TEMP: return small list for screens that expect listings.
  Future<List<Product>> listProducts({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List<Product>.generate(limit, (i) {
      return Product(
        id: 'demo_$i',
        title: 'Demo Item #$i',
        priceAmount: 10.0 + i,
        priceCurrency: 'USD',
        description: 'Item number $i',
        imageUris: const [],
        sellerId: 'demo-user',
      );
    });
  }
}

