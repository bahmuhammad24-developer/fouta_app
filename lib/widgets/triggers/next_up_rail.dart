// lib/widgets/triggers/next_up_rail.dart
import 'package:flutter/material.dart';

/// Lightweight model for recommendations in the rail.
/// Map it from your Post/Short model where you integrate.
class NextUpItem {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String? subtitle;

  const NextUpItem({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    this.subtitle,
  });
}

class NextUpRail extends StatelessWidget {
  final List<NextUpItem> items;
  final ValueChanged<String> onTapItem;
  final EdgeInsetsGeometry padding;

  const NextUpRail({
    super.key,
    required this.items,
    required this.onTapItem,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0),
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Text(
            'Next up',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _RailCard(item: item, onTap: onTapItem);
            },
          ),
        ),
      ],
    );
  }
}

class _RailCard extends StatelessWidget {
  final NextUpItem item;
  final ValueChanged<String> onTap;

  const _RailCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return InkWell(
      onTap: () => onTap(item.id),
      borderRadius: radius,
      child: Ink(
        width: 200,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: Theme.of(context).colorScheme.surfaceVariant,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  item.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: Colors.black12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
