import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onTap});

  final Map<String, dynamic> product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: product['imageUrl'] != null
            ? Image.network(product['imageUrl'], width: 56, height: 56, fit: BoxFit.cover)
            : const Icon(Icons.shopping_bag),
        title: Text(product['name'] ?? 'Unknown'),
        subtitle: Text(product['price']?.toString() ?? ''),
      ),
    );
  }
}
