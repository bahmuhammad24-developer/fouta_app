// lib/widgets/full_screen_video_player.dart
import 'package:fouta_app/services/video_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:fouta_app/utils/video_controller_extensions.dart';

class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final Duration initialPosition;

  FullScreenVideoPlayer({
    Key? key,
    required this.videoUrl,
    required this.initialPosition,
  }) : super(key: key ?? ValueKey(videoUrl));

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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final file = await _cacheService.getFile(widget.videoUrl);
      final uri = Uri.file(file.path).toString();
      await _player.open(Media(uri), play: true);
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
    _controller?.dispose();
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : (_controller != null)
                      ? Video(
                          key: ValueKey(widget.videoUrl),
                          controller: _controller!,
                          controls: AdaptiveVideoControls,
                        )
                      : const Text("Error loading video.", style: TextStyle(color: Colors.white)),
            ),
            // Close button overlay
            if (_showControls)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}