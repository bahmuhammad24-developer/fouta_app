import 'package:flutter/material.dart';

import 'marketplace_service.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final images = product.urls;
    return Scaffold(
      appBar: AppBar(title: Text(product.title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: images.isNotEmpty
                ? PageView(
                    children: images
                        .map((u) => Image.network(u, fit: BoxFit.contain))
                        .toList(),
                  )
                : Container(
                    color: Colors.grey.shade300,
                    child: const Center(child: Icon(Icons.image, size: 48)),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('\$${product.price.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                Text('Seller: ${product.authorId}'),
                if (product.description != null) ...[
                  const SizedBox(height: 8),
                  Text(product.description!),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Contact Seller'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
