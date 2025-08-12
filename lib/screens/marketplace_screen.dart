import 'package:flutter/material.dart';
import 'package:fouta_app/features/marketplace/marketplace_service.dart';
import 'package:fouta_app/features/marketplace/product_card.dart';
import 'package:fouta_app/features/marketplace/product_detail_screen.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = MarketplaceService();
    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.products(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snap.data!;
          if (products.isEmpty) {
            return const Center(child: Text('No products available'));
          }
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: product)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
