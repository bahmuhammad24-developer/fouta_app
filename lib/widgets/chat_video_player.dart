// lib/widgets/chat_video_player.dart
import 'package:fouta_app/services/video_cache_service.dart';
import 'package:fouta_app/widgets/full_screen_video_player.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class ChatVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const ChatVideoPlayer({super.key, required this.videoUrl});

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
    _player.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final file = await _cacheService.getFile(widget.videoUrl);
      await _player.open(Media(file.path));
      if (!mounted) return;

      setState(() {
        _controller = VideoController(_player);
        _isInitialized = true;
      });
      _player.setPlaylistMode(PlaylistMode.single);
    } catch (e) {
      debugPrint("Error initializing chat video: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
        controller: _controller!,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      ),
    );
  }
}