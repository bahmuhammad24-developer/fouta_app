import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/marketplace/marketplace_service.dart';
import '../features/marketplace/product_card.dart';
import '../features/monetization/monetization_service.dart';
import '../utils/app_flags.dart';
import 'chat_screen.dart';

class SellerProfileScreen extends StatelessWidget {
  SellerProfileScreen({super.key, required this.sellerId, MarketplaceService? service})
      : _service = service ?? MarketplaceService();

  final String sellerId;
  final MarketplaceService _service;

  @override
  Widget build(BuildContext context) {
    final monetization = MonetizationService();
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: Text('Seller $sellerId')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(otherUserId: sellerId),
                      ),
                    );
                  },
                  child: const Text('Message seller'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    const amount = 5.0;
                    if (amount <= 0) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Enter an amount greater than zero',
                              semanticsLabel:
                                  'Enter an amount greater than zero',
                            ),
                          ),
                        );
                      }
                      return;
                    }
                    if (!AppFlags.paymentsEnabled) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Payments are disabled. Please try again later.',
                              semanticsLabel:
                                  'Payments are disabled. Please try again later.',
                            ),
                          ),
                        );
                      }
                      return;
                    }
                    final id = await monetization.createTipIntent(
                      amount: amount,
                      currency: 'USD',
                      targetUserId: sellerId,
                      createdBy: user?.uid ?? 'anon',
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
                  child: const Text('Support Creator'),
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
