import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/marketplace/marketplace_service.dart';
import '../features/marketplace/product_card.dart';
import 'package:fouta_app/features/monetization/monetization_service.dart';
import 'package:fouta_app/widgets/fouta_button.dart';
import 'chat_screen.dart';

class SellerProfileScreen extends StatelessWidget {
  SellerProfileScreen({
    super.key,
    required this.sellerId,
    MarketplaceService? service,
    this.createdBy,
  }) : _service = service ?? MarketplaceService();

  final String sellerId;
  final MarketplaceService _service;
  final String? createdBy;

  @override
  Widget build(BuildContext context) {
    final monetization = MonetizationService();
    final userId = createdBy ?? FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    return Scaffold(
      appBar: AppBar(title: Text('Seller $sellerId')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FoutaButton(
                  label: 'Message seller',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(otherUserId: sellerId),
                      ),
                    );
                  },
                  primary: false,
                  expanded: true,
                ),
                const SizedBox(height: 8),
                FoutaButton(
                  label: 'Support Creator',
                  primary: true,
                  onPressed: () async {
                    const amount = 5.0;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Amount must be greater than zero'),
                        ),
                      );
                      return;
                    }
                    if (!PAYMENTS_ENABLED) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payments disabled—coming soon'),
                        ),
                      );
                      return;
                    }
                    final id = await monetization.createTipIntent(
                      amount: amount,
                      currency: 'USD',
                      targetUserId: sellerId,
                      createdBy: userId,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Support intent: $id',
                            semanticsLabel: 'Support intent: $id',
                          ),
                        ),
                      );
                    }
                    // TODO: connect to payment provider once approved.
                  },
                  expanded: true,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _service.streamProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final products =
                    (snapshot.data ?? []).where((p) => p.sellerId == sellerId).toList();
                if (products.isEmpty) {
                  return const Center(child: Text('No products'));
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3 / 4,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductCard(product: product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

