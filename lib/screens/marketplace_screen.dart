import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../features/marketplace/marketplace_service.dart';
import '../features/marketplace/product_detail_screen.dart';
import 'marketplace_filters_sheet.dart';
import 'seller_profile_screen.dart';
import '../widgets/refresh_scaffold.dart';
import '../widgets/safe_stream_builder.dart';
import '../widgets/progressive_image.dart';
import '../widgets/skeleton.dart';

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
      body: SafeStreamBuilder<List<Product>>(
        stream: _service.streamProducts(
          category: _filters.category,
          minPrice: _filters.minPrice,
          maxPrice: _filters.maxPrice,
          query: _filters.query,
        ),
        builder: (context, snapshot) {
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return RefreshScaffold(
              onRefresh: () async {},
              slivers: const [],
              empty: const Card(
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
              return RefreshScaffold(
                onRefresh: () async {},
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(8),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 3 / 4,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = products[index];
                          try {
                            return _buildProductCard(product, userId);
                          } catch (e) {
                            if (kDebugMode) {
                              print('Error rendering product ${product.id}: $e');
                            }
                            return const SizedBox.shrink();
                          }
                        },
                        childCount: products.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product, String userId) {
    final image = product.urls.isNotEmpty ? product.urls.first : null;
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(child: Skeleton.rect()),
                  if (image != null)
                    Positioned.fill(
                      child: ProgressiveImage(
                        imageUrl: image,
                        thumbUrl: image,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    const Positioned.fill(
                      child: Icon(Icons.image, size: 48),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: Icon(
                        product.favoriteUserIds.contains(userId)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: product.favoriteUserIds.contains(userId)
                            ? Colors.red
                            : Colors.white,
                      ),
                      onPressed: () => _service.toggleFavorite(product.id, userId),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                product.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('${product.currency}${product.price.toStringAsFixed(2)}'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SellerProfileScreen(sellerId: product.sellerId),
                    ),
                  );
                },
                child: Text(
                  product.sellerId,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
