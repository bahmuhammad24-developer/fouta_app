import 'package:flutter/material.dart';
import '../../screens/chat_screen.dart';

/// ProductDetailScreen
/// A minimal, safe, and compilable implementation that expects a `product`
/// object (map/model) with these fields:
/// - id
/// - title
/// - priceCurrency
/// - priceAmount (num/double)
/// - sellerId
/// - description (nullable)
/// - imageUris (List or List<Uri> or List<String>) - optional
///
/// NOTE: We keep `product` typed as `dynamic` to avoid tight coupling with
/// a specific model class name/import. This compiles even if your model lives
/// elsewhere. You can tighten the type later.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  final dynamic product;

  @override
  Widget build(BuildContext context) {
    // Defensive reads with sensible fallbacks
    final String title = (product?.title ?? product?['title'] ?? 'Product').toString();
    final String sellerId = (product?.sellerId ?? product?['sellerId'] ?? '').toString();

    final String currency =
        (product?.priceCurrency ?? product?['priceCurrency'] ?? '').toString();

    final num amountNum =
        (product?.priceAmount ?? product?['priceAmount'] ?? 0) as num;

    final String price =
        currency.isEmpty ? amountNum.toStringAsFixed(2) : '$currency ${amountNum.toStringAsFixed(2)}';

    final String? descriptionRaw =
        (product?.description ?? product?['description']) as String?;
    final String? description =
        (descriptionRaw == null || descriptionRaw.trim().isEmpty) ? null : descriptionRaw.trim();

    // Images are optional; normalize to List<String> if present
    final List<String> images = (() {
      final raw = product?.imageUris ?? product?['imageUris'];
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      return <String>[];
    })();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simple image preview strip (only if we have images)
            if (images.isNotEmpty) ...[
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, i) => AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        images[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade300,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: images.length,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Title & price
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            if (sellerId.isNotEmpty)
              Text('Seller: $sellerId', style: Theme.of(context).textTheme.bodyMedium),

            if (description != null) ...[
              const SizedBox(height: 12),
              Text(description),
            ],

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Keep original navigation intent.
                    // If ChatScreen import exists in this file/project, this will work.
                    // Otherwise, leave this here and wire the import later.
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(otherUserId: sellerId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Message Seller'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // Minimal purchase sheet; replace with your existing flow if needed.
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Confirm Purchase', style: Theme.of(ctx).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(title),
                            Text(price),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: () {
                                    // TODO: hook up your purchase flow
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Purchase flow started')),
                                    );
                                  },
                                  child: const Text('Buy Now'),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('Buy Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
