import 'package:flutter/material.dart';

import 'link_preview_service.dart';

/// Displays Open Graph data with safe fallbacks.
class LinkPreviewCard extends StatelessWidget {
  const LinkPreviewCard({super.key, required this.data});

  final LinkPreviewData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (data.description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (data.siteName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data.siteName!,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (data.imageUrl == null) {
      return _placeholder();
    }
    return Image.network(
      data.imageUrl!,
      height: 150,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        height: 150,
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        child: const Icon(Icons.link, size: 40, color: Colors.black45),
      );
}

