import 'package:flutter/material.dart';
import 'package:fouta_app/features/discovery/discovery_service.dart';

class NextUpRail extends StatelessWidget {
  const NextUpRail({super.key, required this.onSelected, DiscoveryService? service})
      : _service = service ?? DiscoveryService();

  final DiscoveryService _service;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final recs = _service.recommendedPosts().take(3).toList();
    if (recs.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recs.length,
        itemBuilder: (context, i) {
          final item = recs[i];
          return GestureDetector(
            onTap: () => onSelected(item),
            child: Card(
              child: SizedBox(
                width: 160,
                child: Center(child: Text(item, maxLines: 2)),
              ),
            ),
          );
        },
      ),
    );
  }
}
