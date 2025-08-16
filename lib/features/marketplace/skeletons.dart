import 'package:flutter/material.dart';

import '../../widgets/skeleton.dart';

/// Skeleton card matching [ProductCard] layout.
class MarketplaceCardSkeleton extends StatelessWidget {
  const MarketplaceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AspectRatio(aspectRatio: 4 / 3, child: Skeleton.rect()),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Skeleton.line(width: 80),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Skeleton.line(width: 40),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Grid of [MarketplaceCardSkeleton] used while loading.
class MarketplaceListSkeleton extends StatelessWidget {
  const MarketplaceListSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 3 / 4,
          ),
          itemCount: count,
          itemBuilder: (_, __) => const MarketplaceCardSkeleton(),
        );
      },
    );
  }
}
