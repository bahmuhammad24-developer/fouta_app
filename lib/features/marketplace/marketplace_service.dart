import 'package:cloud_firestore/cloud_firestore.dart';

class MarketplaceService {
  MarketplaceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Map<String, dynamic>>> products() {
    _log('Fetching products');
    return _firestore
        .collection('products')
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<Map<String, dynamic>?> product(String id) async {
    final doc = await _firestore.collection('products').doc(id).get();
    _log('Fetched product $id');
    return doc.data();
  }

  void _log(String message) {
    final now = DateTime.now().toIso8601String();
    // ignore: avoid_print
    print('[$now][MarketplaceService] $message');
  }
}
