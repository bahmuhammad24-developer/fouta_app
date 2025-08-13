import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:fouta_app/features/marketplace/marketplace_service.dart';
import 'package:fouta_app/features/marketplace/product_card.dart';
import 'package:fouta_app/features/marketplace/product_detail_screen.dart';

class MarketplaceScreen extends StatelessWidget {
  MarketplaceScreen({super.key, MarketplaceService? service})
      : _service = service ?? MarketplaceService();

  final MarketplaceService _service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: _service.streamProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No listings yet'),
                ),
              ),
            ),
          );
        }
        return Scaffold(
          body: LayoutBuilder(
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
                    );
                  } catch (e) {
                    debugPrint('Error rendering product ${product.id}: $e');
                    return const SizedBox.shrink();
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}
