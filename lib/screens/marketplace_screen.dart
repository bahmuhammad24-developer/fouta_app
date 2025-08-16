import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../features/marketplace/marketplace_service.dart';
import '../features/marketplace/product_detail_screen.dart';
import 'package:fouta_app/features/marketplace/product_card.dart';
import 'package:fouta_app/features/marketplace/create_product_nav.dart';
import '../features/marketplace/filters/marketplace_filters.dart';
import '../features/marketplace/filters/filter_drawer.dart';
import '../features/marketplace/skeletons.dart';
import 'seller_profile_screen.dart';
import '../widgets/refresh_scaffold.dart';
import '../widgets/safe_stream_builder.dart';
import 'package:fouta_app/features/marketplace/onboarding/seller_onboarding_nav.dart';
import 'marketplace_filters_sheet.dart';
import 'seller_profile_screen.dart';
import '../widgets/refresh_scaffold.dart';
import '../widgets/safe_stream_builder.dart';
import '../widgets/progressive_image.dart';
import '../widgets/skeleton.dart';
import 'package:fouta_app/design/components/f_button.dart';
import 'package:fouta_app/design/components/f_chip.dart';
import 'package:fouta_app/design/tokens.dart';
import '../widgets/fouta_button.dart';


// TODO(IA): Align screen layout with docs/design/information-architecture.md after DS v1 adoption
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final MarketplaceService _service = MarketplaceService();

  final MarketplaceFiltersRepository _repo = MarketplaceFiltersRepository();
  MarketplaceFilters _filters = const MarketplaceFilters();
  StreamSubscription<MarketplaceFilters>? _sub;


  void _openFilters(String uid) {
    showModalBottomSheet(
      context: context,
      builder: (_) => MarketplaceFilterDrawer(repository: _repo, uid: uid),
    );
  }

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _sub = _repo.watch(uid).listen((f) {
        setState(() => _filters = f);
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            onPressed: () => _openFilters(userId),
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: SafeStreamBuilder<List<Product>>(
        stream: _service.streamProducts(filters: _filters, limit: 20),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const MarketplaceListSkeleton();
          }
          final products = snapshot.data ?? [];
          final hasListings = products.any((p) => p.sellerId == userId);
          Widget content;
          if (products.isEmpty) {
            content = const Center(child: Text('No products match your filters'));
          } else {
            content = LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

                return FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 3 / 4,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        onFavorite: () => _service.toggleFavorite(product.id, userId),
                        isFavorited: product.favoriteUserIds.contains(userId),
                        onSellerTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SellerProfileScreen(sellerId: product.sellerId),
                            ),
                          );
                        },
                      );

                    },
                  ),
                );
              },
            );
          }

          return Column(
            children: [
              if (user != null)
                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('meta')
                      .doc('onboarding')
                      .get(),
                  builder: (context, snap) {
                    final data = snap.data?.data();
                    final incomplete = (data?['completed'] ?? true) == false;
                    if (incomplete) {
                      return ListTile(
                        title: const Text('Finish setting up your shop'),
                        trailing: TextButton(
                          onPressed: () => navigateToSellerOnboarding(context),
                          child: const Text('Resume'),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              if (user != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FButton(
                    label: hasListings ? 'Sell' : 'Start Selling',
                    onPressed: () async {
                      if (hasListings) {
                        await navigateToCreateProduct(context);
                      } else {
                        await navigateToSellerOnboarding(context);
                      }
                    },
                    expanded: true,
                    tier: FTier.t1,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: FSpacing.s2,
                  children: _categories.map((c) {
                    final selected =
                        _filters.category == null && c == 'All' ||
                            _filters.category == c;
                    return FChip(
                      label: c,
                      tier: FTier.t3,
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _filters = MarketplaceFilters(
                            category: c == 'All' ? null : c,
                            minPrice: _filters.minPrice,
                            maxPrice: _filters.maxPrice,
                            query: _filters.query,
                          );
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }

}
