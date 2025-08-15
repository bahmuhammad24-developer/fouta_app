import 'package:cloud_firestore/cloud_firestore.dart';

import '../../main.dart';
import '../../utils/json_safety.dart';

/// Marketplace product domain model.
class Product {
  final String id;
  final String title;
  final double priceAmount;       // canonical
  final String priceCurrency;     // canonical
  final String? description;
  final List<Uri> imageUris;      // canonical
  final String sellerId;
  final List<String> favoriteUserIds; // optional favorites

  Product({
    required this.id,
    required this.title,
    required this.priceAmount,
    required this.priceCurrency,
    required this.sellerId,
    this.description,
    List<Uri>? imageUris,
    List<String>? favoriteUserIds,
  })  : imageUris = imageUris ?? const [],
        favoriteUserIds = favoriteUserIds ?? const [];

  // Backward-compatible aliases expected by UI
  double get price => priceAmount;
  String get currency => priceCurrency;
  List<String> get urls => imageUris.map((u) => u.toString()).toList();

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    final rawUrls = (map['imageUris'] ?? map['urls'] ?? []) as List?;
    final parsedUris = (rawUrls ?? [])
        .map((e) => Uri.tryParse(e.toString()))
        .whereType<Uri>()
        .toList();

    return Product(
      id: id,
      title: (map['title'] ?? '').toString(),
      priceAmount: (map['priceAmount'] is num)
          ? (map['priceAmount'] as num).toDouble()
          : double.tryParse('${map['priceAmount']}') ?? 0.0,
      priceCurrency: (map['priceCurrency'] ?? map['currency'] ?? 'USD').toString(),
      description: (map['description'] as String?)?.trim(),
      imageUris: parsedUris,
      sellerId: (map['sellerId'] ?? '').toString(),
      favoriteUserIds: ((map['favoriteUserIds'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'priceAmount': priceAmount,
        'priceCurrency': priceCurrency,
        'description': description,
        'imageUris': imageUris.map((u) => u.toString()).toList(),
        'sellerId': sellerId,
        'favoriteUserIds': favoriteUserIds,
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
    required String currency,
    String? description,
    List<Uri>? imageUris,
    required String createdBy,
  }) async {
    // Simulate latency and return a synthetic ID
    await Future.delayed(const Duration(milliseconds: 300));
    // ignore: unused_local_variable
    final priceCurrency = currency; // preserve compatibility
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
      favoriteUserIds: const ['demo-user'],
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
        favoriteUserIds: i.isEven ? const ['demo-user'] : const [],
      );
    });
  }

  /// Stream products for list UIs (stub).
  Stream<List<Product>> streamProducts({
    String? category,
    double? minPrice,
    double? maxPrice,
    String? query,
    int limit = 20,
  }) async* {
    yield await listProducts(limit: limit);
    await for (final _ in Stream<void>.periodic(const Duration(seconds: 10))) {
      yield await listProducts(limit: limit);
    }
  }
}

