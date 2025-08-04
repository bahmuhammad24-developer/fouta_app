// lib/widgets/video_player_widget.dart
import 'dart:async';
import 'package:fouta_app/services/video_cache_service.dart';
import 'package:fouta_app/services/video_player_manager.dart';
import 'package:fouta_app/widgets/full_screen_video_player.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:fouta_app/utils/video_controller_extensions.dart';
import 'package:provider/provider.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String videoId; // Unique ID for the video, e.g., postId
  final double? aspectRatio;
  final bool areControlsVisible;
  final bool shouldInitialize; // New property to trigger loading

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.videoId,
    this.aspectRatio,
    required this.areControlsVisible,
    required this.shouldInitialize,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  final VideoCacheService _cacheService = VideoCacheService();
  Player? _player;
  VideoController? _controller;
  bool _isInitialized = false;
  late final VideoPlayerManager _playerManager;

  @override
  void initState() {
    super.initState();
    _playerManager = Provider.of<VideoPlayerManager>(context, listen: false);
    if (widget.shouldInitialize) {
      _initializePlayer();
    }
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldInitialize && !oldWidget.shouldInitialize && ! _isInitialized) {
      _initializePlayer();
    }
    if (!widget.shouldInitialize && oldWidget.shouldInitialize) {
      _releasePlayer();
    }
  }

  @override
  void dispose() {
    _releasePlayer();
    super.dispose();
  }

  void _initializePlayer() {
    if (_player != null) return;
    final requestedPlayer = _playerManager.requestPlayer(widget.videoId);
    // If the pool is exhausted, leave _player as null. The UI will show a fallback.
    if (requestedPlayer == null) {
      return;
    }
    setState(() {
      _player = requestedPlayer;
    });
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    if (_player == null || _isInitialized) return;

    try {
      final file = await _cacheService.getFile(widget.videoUrl);
      await _player!.open(Media(file.path));
      if (!mounted) return;

      setState(() {
        _controller = VideoController(_player!);
        _isInitialized = true;
      });
      _player!.setPlaylistMode(PlaylistMode.single);
      _player!.setVolume(0);
      _player!.play();

    } catch (e) {
      debugPrint("Error initializing video: $e");
    }
  }
  
  void _releasePlayer() {
    if (_player != null) {
      _controller?.dispose();
      _playerManager.releasePlayer(widget.videoId);
      if (mounted) {
        setState(() {
          _player = null;
          _controller = null;
          _isInitialized = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized && _controller != null && _player != null) {
      return _buildVideoPlayer();
    }
    // If no player could be acquired, show a message instead of a spinner
    if (_player == null) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio ?? 16 / 9,
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: const Text(
            'Video unavailable. Please try again later.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    // Otherwise, show loading spinner until initialization
    return AspectRatio(
      aspectRatio: widget.aspectRatio ?? 16 / 9,
      child: _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.black,
      child: const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  Widget _buildVideoPlayer() {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: widget.aspectRatio ?? 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Video(
                controller: _controller!,
                controls: null,
              ),
              StreamBuilder<bool>(
                stream: _player!.stream.playing,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data ?? false;
                  if (isPlaying || widget.areControlsVisible) return const SizedBox.shrink();
                  return const IgnorePointer(
                    child: Icon(Icons.play_arrow, color: Colors.white70, size: 60.0),
                  );
                },
              ),
            ],
          ),
        ),
        _DynamicVideoControls(
          player: _player!,
          videoUrl: widget.videoUrl,
          showControls: widget.areControlsVisible,
        ),
      ],
    );
  }
}

class _DynamicVideoControls extends StatelessWidget {
  const _DynamicVideoControls({
    required this.player,
    required this.videoUrl,
    required this.showControls,
  });

  final Player player;
  final String videoUrl;
  final bool showControls;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Column(
        children: [
          StreamBuilder<Duration>(
            stream: player.stream.position,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = player.state.duration;
              double progress = 0.0;
              if (duration.inMilliseconds > 0) {
                progress = position.inMilliseconds / duration.inMilliseconds;
              }
              return LinearProgressIndicator(
                value: progress.isNaN ? 0 : progress,
                minHeight: 2,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
              );
            },
          ),
          if (showControls)
            Row(
              children: [
                IconButton(
                  icon: StreamBuilder<bool>(
                    stream: player.stream.playing,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data ?? false;
                      return Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      );
                    },
                  ),
                  onPressed: () => player.playOrPause(),
                ),
                Expanded(
                  child: StreamBuilder<Duration>(
                    stream: player.stream.position,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final duration = player.state.duration;
                      return SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                          trackHeight: 2.0,
                        ),
                        child: Slider(
                          value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
                          min: 0.0,
                          max: duration.inMilliseconds.toDouble() + 1,
                          onChanged: (val) => player.seek(Duration(milliseconds: val.toInt())),
                          activeColor: Theme.of(context).colorScheme.secondary,
                          inactiveColor: Colors.white.withOpacity(0.5),
                        ),
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: StreamBuilder<double>(
                    stream: player.stream.volume,
                    builder: (context, snapshot) {
                      final volume = snapshot.data ?? 100.0;
                      return Icon(
                        volume == 0 ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                      );
                    },
                  ),
                  onPressed: () {
                    final currentVolume = player.state.volume;
                    player.setVolume(currentVolume == 0 ? 100.0 : 0.0);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                  onPressed: () {
                    player.pause();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenVideoPlayer(
                          videoUrl: videoUrl,
                          initialPosition: player.state.position,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}