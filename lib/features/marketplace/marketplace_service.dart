import 'package:cloud_firestore/cloud_firestore.dart';

import '../../main.dart';
import '../../utils/json_safety.dart';

class Product {
  Product({
    required this.id,
    required this.sellerId,
    required this.urls,
    required this.title,
    required this.category,
    required this.price,
    required this.currency,
    this.description,
    required this.favoriteUserIds,
    this.createdAt,
  });

  final String id;
  final String sellerId;
  final List<String> urls;
  final String title;
  final String category;
  final double price;
  final String currency;
  final String? description;
  final List<String> favoriteUserIds;
  final DateTime? createdAt;

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Product(
      id: doc.id,
      sellerId: data['sellerId']?.toString() ?? '',
      urls: asStringList(data['urls']),
      title: data['title']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      price: asDoubleOrNull(data['price']) ?? 0.0,
      currency: data['currency']?.toString() ?? 'USD',
      description: data['description']?.toString(),
      favoriteUserIds: asStringList(data['favoriteUserIds']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'sellerId': sellerId,
        'urls': urls,
        'title': title,
        'category': category,
        'price': price,
        'currency': currency,
        if (description != null) 'description': description,
        'favoriteUserIds': favoriteUserIds,
        'createdAt': FieldValue.serverTimestamp(),
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

  Stream<List<Product>> streamProducts({
    String? category,
    double? minPrice,
    double? maxPrice,
    String? query,
  }) {
    Query<Map<String, dynamic>> ref =
        _collection.orderBy('createdAt', descending: true);
    if (category != null && category.isNotEmpty) {
      ref = ref.where('category', isEqualTo: category);
    }
    if (minPrice != null) {
      ref = ref.where('price', isGreaterThanOrEqualTo: minPrice);
    }
    if (maxPrice != null) {
      ref = ref.where('price', isLessThanOrEqualTo: maxPrice);
    }
    if (query != null && query.isNotEmpty) {
      ref = ref
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '$query\uf8ff');
    }
    return ref.snapshots().map((s) => s.docs.map(Product.fromDoc).toList());
  }

  Future<void> createProduct(Product product) => _collection.add(product.toMap());

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
