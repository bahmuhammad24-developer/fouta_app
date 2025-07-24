// lib/widgets/full_screen_video_player.dart
import 'package:fouta_app/services/video_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final Duration initialPosition;

  const FullScreenVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.initialPosition,
  });

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  final VideoCacheService _cacheService = VideoCacheService();
  late final Player _player = Player();
  VideoController? _controller;
  bool _showControls = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final file = await _cacheService.getFile(widget.videoUrl);
      await _player.open(Media(file.path), play: true);
      await _player.seek(widget.initialPosition);

      if (mounted) {
        setState(() {
          _controller = VideoController(_player);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error initializing fullscreen player: $e");
      if(mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not play video.")));
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showControls ? AppBar(backgroundColor: Colors.transparent, elevation: 0) : null,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : (_controller != null)
                  ? Video(controller: _controller!, controls: AdaptiveVideoControls)
                  : const Text("Error loading video.", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}