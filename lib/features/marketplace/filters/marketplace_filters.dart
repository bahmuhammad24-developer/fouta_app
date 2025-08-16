import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../main.dart';

/// Sort options for marketplace listings.
enum MarketplaceSort { newest, priceAsc, priceDesc }

/// User-selected filters for marketplace queries.
class MarketplaceFilters {
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final double? radiusKm;
  final MarketplaceSort sort;

  const MarketplaceFilters({
    this.category,
    this.minPrice,
    this.maxPrice,
    this.radiusKm,
    this.sort = MarketplaceSort.newest,
  });

  factory MarketplaceFilters.fromMap(Map<String, dynamic>? map) {
    map ??= const {};
    return MarketplaceFilters(
      category: map['category'] as String?,
      minPrice: (map['minPrice'] as num?)?.toDouble(),
      maxPrice: (map['maxPrice'] as num?)?.toDouble(),
      radiusKm: (map['radiusKm'] as num?)?.toDouble(),
      sort: MarketplaceSort.values.firstWhere(
        (s) => s.name == (map['sort'] as String?),
        orElse: () => MarketplaceSort.newest,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        if (category != null) 'category': category,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (radiusKm != null) 'radiusKm': radiusKm,
        'sort': sort.name,
      };

  MarketplaceFilters copyWith({
    String? category,
    double? minPrice,
    double? maxPrice,
    double? radiusKm,
    MarketplaceSort? sort,
  }) {
    return MarketplaceFilters(
      category: category ?? this.category,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      radiusKm: radiusKm ?? this.radiusKm,
      sort: sort ?? this.sort,
    );
  }
}

/// Handles persistence of [MarketplaceFilters] for each user.
class MarketplaceFiltersRepository {
  MarketplaceFiltersRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _firestore
      .collection('artifacts')
      .doc(APP_ID)
      .collection('public')
      .doc('data')
      .collection('users')
      .doc(uid)
      .collection('meta')
      .doc('marketplaceFilters');

  Future<void> save(String uid, MarketplaceFilters filters) async {
    await _doc(uid).set(filters.toMap(), SetOptions(merge: true));
  }

  Future<MarketplaceFilters> fetch(String uid) async {
    final snap = await _doc(uid).get();
    return MarketplaceFilters.fromMap(snap.data());
  }

  Stream<MarketplaceFilters> watch(String uid) {
    return _doc(uid).snapshots().map((s) => MarketplaceFilters.fromMap(s.data()));
  }
}
