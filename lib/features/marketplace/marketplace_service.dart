import 'package:cloud_firestore/cloud_firestore.dart';

import '../../main.dart';
import '../../utils/json_safety.dart';

class Product {
  Product({
    required this.id,
    required this.authorId,
    required this.urls,
    required this.title,
    required this.price,
    this.description,
    required this.favoriteIds,
    this.createdAt,
  });

  final String id;
  final String authorId;
  final List<String> urls;
  final String title;
  final double price;
  final String? description;
  final List<String> favoriteIds;
  final DateTime? createdAt;

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Product(
      id: doc.id,
      authorId: data['authorId']?.toString() ?? '',
      urls: asStringList(data['urls']),
      title: data['title']?.toString() ?? '',
      price: asDoubleOrNull(data['price']) ?? 0.0,
      description: data['description']?.toString(),
      favoriteIds: asStringList(data['favoriteIds']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'urls': urls,
        'title': title,
        'price': price,
        if (description != null) 'description': description,
        'favoriteIds': favoriteIds,
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

  Stream<List<Product>> streamProducts() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Product.fromDoc).toList());
  }

  Future<void> createProduct(Product product) => _collection.add(product.toMap());

  Future<void> toggleFavorite(String productId, String userId) async {
    final doc = _collection.doc(productId);
    final snap = await doc.get();
    final favs = asStringList(snap.data()?['favoriteIds']);
    final value = favs.contains(userId)
        ? FieldValue.arrayRemove([userId])
        : FieldValue.arrayUnion([userId]);
    await doc.update({'favoriteIds': value});
  }
}
