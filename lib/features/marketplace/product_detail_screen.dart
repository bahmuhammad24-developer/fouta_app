import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product['name'] ?? 'Product')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product['imageUrl'] != null)
              Image.network(product['imageUrl'], height: 200),
            const SizedBox(height: 16),
            Text(product['description'] ?? ''),
            const Spacer(),
            Text('Price: ${product['price'] ?? ''}'),
          ],
        ),
      ),
    );
  }
}
