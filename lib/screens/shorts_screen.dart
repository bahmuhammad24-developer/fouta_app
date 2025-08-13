import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:fouta_app/features/shorts/shorts_service.dart';
import 'package:fouta_app/widgets/video_player_widget.dart';

class ShortsScreen extends StatelessWidget {
  ShortsScreen({super.key, ShortsService? service})
      : _service = service ?? ShortsService();

  final ShortsService _service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Short>>(
      stream: _service.streamShorts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No shorts yet'),
                ),
              ),
            ),
          );
        }
        return Scaffold(
          body: PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final short = items[index];
              try {
                final likeCount = short.likeIds.length;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoPlayerWidget(
                      videoUrl: short.url,
                      videoId: short.id,
                      aspectRatio: short.aspectRatio,
                      areControlsVisible: false,
                      shouldInitialize: true,
                    ),
                    Positioned(
                      right: 16,
                      bottom: 80,
                      child: Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.favorite, color: Colors.white),
                            onPressed: () {},
                          ),
                          Text('$likeCount',
                              style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 16),
                          IconButton(
                            icon: const Icon(Icons.comment, color: Colors.white),
                            onPressed: () {
                              // TODO: Replace with ShortDetailScreen using
                              // FoutaTransitions.fadeIn once implemented.
                            },
                          ),
                          const SizedBox(height: 16),
                          IconButton(
                            icon: const Icon(Icons.share, color: Colors.white),
                            onPressed: () {},
                          ),
                          const SizedBox(height: 16),
                          IconButton(
                            icon: const Icon(Icons.person_add, color: Colors.white),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } catch (e, st) {
                debugPrint('Error rendering short ${short.id}: $e');
                return const SizedBox.shrink();
              }
            },
          ),
        );
      },
    );
  }
}
