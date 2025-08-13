import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../features/marketplace/marketplace_service.dart';
import '../features/marketplace/product_card.dart';
import '../features/marketplace/product_detail_screen.dart';
import 'marketplace_filters_sheet.dart';
import 'seller_profile_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final MarketplaceService _service = MarketplaceService();
  MarketplaceFilters _filters = MarketplaceFilters();

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      builder: (_) => MarketplaceFiltersSheet(
        initial: _filters,
        onApply: (f) {
          setState(() => _filters = f);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(onPressed: _openFilters, icon: const Icon(Icons.filter_list)),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: _service.streamProducts(
          category: _filters.category,
          minPrice: _filters.minPrice,
          maxPrice: _filters.maxPrice,
          query: _filters.query,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No listings yet'),
                ),
              ),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  try {
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
                  } catch (e) {
                    if (kDebugMode) {
                      print('Error rendering product ${product.id}: $e');
                    }
                    return const SizedBox.shrink();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
