// lib/widgets/full_screen_video_player.dart
import 'package:fouta_app/services/video_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:fouta_app/utils/video_controller_extensions.dart';
import 'package:fouta_app/utils/snackbar.dart';

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
      // Prefix with `file://` so media_kit reads the local cache file.
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
        AppSnackBar.show(context, 'Could not play video.', isError: true);
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
      backgroundColor: Theme.of(context).colorScheme.onSurface,
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            Center(
              child: _isLoading
                  ? CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary)
                  : (_controller != null)
                      ? Video(
                          key: ValueKey(widget.videoUrl),
                          controller: _controller!,
                          controls: AdaptiveVideoControls,
                        )
                      : Text("Error loading video.", style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            ),
            // Close button overlay
            if (_showControls)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: IconButton(
                  icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}