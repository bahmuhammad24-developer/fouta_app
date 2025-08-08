// lib/widgets/chat_video_player.dart
import 'package:fouta_app/services/video_cache_service.dart';
import 'package:fouta_app/widgets/full_screen_video_player.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:fouta_app/utils/video_controller_extensions.dart';

class ChatVideoPlayer extends StatefulWidget {
  final String videoUrl;
  ChatVideoPlayer({Key? key, required this.videoUrl})
      : super(key: key ?? ValueKey(videoUrl));

  @override
  State<ChatVideoPlayer> createState() => _ChatVideoPlayerState();
}

class _ChatVideoPlayerState extends State<ChatVideoPlayer> {
  final VideoCacheService _cacheService = VideoCacheService();
  late final Player _player = Player();
  VideoController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _player.dispose();
    super.dispose();
  }

  bool _hasError = false;

  Future<void> _initialize() async {
    try {
      final file = await _cacheService.getFile(widget.videoUrl);
      // `media_kit` expects a `file://` URI for local cache entries.
      final uri = Uri.file(file.path).toString();
      await _player.open(Media(uri));
      if (!mounted) return;
      setState(() {
        _controller = VideoController(_player);
        _isInitialized = true;
        _hasError = false;
      });
      _player.setPlaylistMode(PlaylistMode.single);
    } catch (e) {
      debugPrint("Error initializing chat video: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        width: 150,
        height: 150,
        color: Colors.black,
        alignment: Alignment.center,
        child: const Text(
          'Video unavailable',
          style: TextStyle(color: Colors.white70, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (!_isInitialized || _controller == null) {
      return Container(
        width: 150,
        height: 150,
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return GestureDetector(
      onTap: () => _player.playOrPause(),
      child: Video(
        key: ValueKey(widget.videoUrl),
        controller: _controller!,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      ),
    );
  }
}