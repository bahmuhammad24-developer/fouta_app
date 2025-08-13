import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:fouta_app/features/shorts/shorts_service.dart';
import 'package:fouta_app/widgets/video_player_widget.dart';
import 'package:fouta_app/theme/motion.dart';
import 'package:fouta_app/utils/error_reporter.dart';


class ShortsScreen extends StatelessWidget {
  ShortsScreen({super.key, ShortsService? service})
      : _service = service ?? ShortsService();

  final ShortsService _service;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion ? AppDurations.fast : AppDurations.normal;

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

          body: AnimatedSwitcher(
            duration: duration,
            child: PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final short = items[index];
                try {
                  final likeCount = short.likeIds.length;
                  Widget actionButton(IconData icon, VoidCallback onPressed) {
                    final button = IconButton(
                      icon: Icon(icon, color: Colors.white),
                      onPressed: onPressed,
                    );
                    return reduceMotion ? button : animateOnTap(child: button, onTap: onPressed);
                  }

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
                            actionButton(Icons.favorite, () {}),
                            Text('$likeCount',
                                style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 16),
                            actionButton(Icons.comment, () {}),
                            const SizedBox(height: 16),
                            actionButton(Icons.share, () {}),
                            const SizedBox(height: 16),
                            actionButton(Icons.person_add, () {}),
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

          ),
        );
      },
    );
  }
}
