import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// A minimal video player with tap‑to‑pause controls.
class VideoPlayerView extends StatefulWidget {
  const VideoPlayerView({super.key, required this.url, this.autoplay = true});

  final Uri url;
  final bool autoplay;

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView>
    with AutomaticKeepAliveClientMixin {
  late final VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(widget.url)
      ..setLooping(true)
      ..initialize().then((_) {
        setState(() => _initialized = true);
        if (widget.autoplay) _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        if (_controller.value.isPlaying) {
          _controller.pause();
        } else {
          _controller.play();
        }
        setState(() {});
      },
      child: Stack(
        children: [
          VideoPlayer(_controller),
          Positioned(
            bottom: 8,
            left: 8,
            child: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
