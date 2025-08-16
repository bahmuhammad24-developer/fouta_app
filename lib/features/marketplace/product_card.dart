import 'package:flutter/material.dart';

import 'marketplace_service.dart';
import 'package:fouta_app/theme/tokens.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavorite,
    this.isFavorited = false,
    this.onSellerTap,
    this.viewerId,
  });

  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorited;
  final VoidCallback? onSellerTap;
  final String? viewerId;

  @override
  Widget build(BuildContext context) {
    final image = product.urls.isNotEmpty ? product.urls.first : null;
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        focusColor: AppColors.primary.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: image != null
                        ? Semantics(
                            label: 'Product image: ${product.title}',
                            child: Image.network(image, width: double.infinity, fit: BoxFit.cover),
                          )
                        : Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image, size: 48),
                          ),
                  ),
                  if (product.status == 'draft' && product.sellerId == viewerId)
                    const Positioned(
                      top: 4,
                      left: 4,
                      child: Chip(
                        label: Text('Draft'),
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: Icon(
                        isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: isFavorited ? Colors.red : Colors.white,
                      ),
                      onPressed: onFavorite,
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
                softWrap: false,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('${product.currency}${product.price.toStringAsFixed(2)}'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: InkWell(
                onTap: onSellerTap,
                focusColor: AppColors.primary.withOpacity(0.3),
                child: Text(
                  product.sellerId,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
