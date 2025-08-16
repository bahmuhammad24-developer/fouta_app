import 'package:flutter/material.dart';

import 'marketplace_service.dart';
import 'package:fouta_app/theme/tokens.dart';
import '../../widgets/skeleton.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavorite,
    this.isFavorited = false,
    this.onSellerTap,
  });

  final Product product;
  final VoidCallback? onTap;
  final Future<void> Function()? onFavorite;
  final bool isFavorited;
  final VoidCallback? onSellerTap;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late bool _favorited = widget.isFavorited;

  Future<void> _handleFavorite() async {
    setState(() => _favorited = !_favorited);
    if (widget.onFavorite == null) return;
    try {
      await widget.onFavorite!.call();
    } catch (_) {
      // revert and retry once
      setState(() => _favorited = !_favorited);
      try {
        await widget.onFavorite!.call();
        setState(() => _favorited = !_favorited);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update favorite')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.product.urls.isNotEmpty ? widget.product.urls.first : null;
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: widget.onTap,
        focusColor: AppColors.primary.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                children: [
                  Positioned.fill(child: Skeleton.rect()),
                  if (image != null)
                    Positioned.fill(
                      child: Image.network(
                        image,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) {
                            return child;
                          }
                          return Skeleton.rect();
                        },
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                      ),
                    )
                  else
                    const Center(child: Icon(Icons.image, size: 48)),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: Icon(
                        _favorited ? Icons.favorite : Icons.favorite_border,
                        color: _favorited ? Colors.red : Colors.white,
                      ),
                      onPressed: _handleFavorite,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                widget.product.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('${widget.product.currency}${widget.product.price.toStringAsFixed(2)}'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: InkWell(
                onTap: widget.onSellerTap,
                focusColor: AppColors.primary.withOpacity(0.3),
                child: Text(
                  widget.product.sellerId,
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
