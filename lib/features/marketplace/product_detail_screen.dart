import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../screens/chat_screen.dart';
import 'package:fouta_app/features/marketplace/marketplace_service.dart';
import 'package:fouta_app/features/monetization/monetization_service.dart';
import 'package:fouta_app/widgets/fouta_button.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final MarketplaceService _service = MarketplaceService();
  late Future<Product> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getProductById(widget.product.id);
  }

  @override
  Widget build(BuildContext context) {

    final images = product.imageUris.map((u) => u.toString()).toList();
    final user = FirebaseAuth.instance.currentUser;
    final monetization = MonetizationService();
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
                Text('${product.priceCurrency} ${product.priceAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                Text('Seller: ${product.sellerId}'),
                if (product.description != null) ...[
                  const SizedBox(height: 8),
                  Text(product.description!),
                ],
                const SizedBox(height: 16),
                FoutaButton(
                  label: 'Buy',
                  primary: true,
                  onPressed: () async {
                    final id = await monetization.createPurchaseIntent(
                      amount: product.priceAmount,
                      currency: product.priceCurrency,
                      productId: product.id,
                      createdBy: user?.uid ?? 'anon',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Purchase intent: $id')),
                      );
                    }
                    // TODO: Hand off to payment provider once integrated.
                  },
                  expanded: true,
                ),
                const SizedBox(height: 8),
                FoutaButton(
                  label: 'Message Seller',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(otherUserId: product.sellerId),

                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                        '${product.priceCurrency} ${product.priceAmount.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    Text('Seller: ${product.sellerId}'),
                    if (product.description != null) ...[
                      const SizedBox(height: 8),
                      Text(product.description!),
                    ],
                    const SizedBox(height: 16),
                    FoutaButton(
                      label: 'Buy',
                      onPressed: () async {
                        final id = await monetization.createPurchaseIntent(
                          amount: product.priceAmount,
                          currency: product.priceCurrency,
                          productId: product.id,
                          createdBy: user?.uid ?? 'anon',
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Purchase intent: $id')),
                          );
                        }
                        // TODO: Hand off to payment provider once integrated.
                      },
                      expanded: true,
                    ),
                    const SizedBox(height: 8),
                    FoutaButton(
                      label: 'Message Seller',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ChatScreen(otherUserId: product.sellerId),
                          ),
                        );
                      },
                      primary: false,
                      expanded: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
