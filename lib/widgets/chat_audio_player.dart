// lib/widgets/chat_audio_player.dart
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class ChatAudioPlayer extends StatefulWidget {
  final String source;
  final bool isLocal;
  const ChatAudioPlayer({super.key, required this.source, this.isLocal = false});

  @override
  State<ChatAudioPlayer> createState() => _ChatAudioPlayerState();
}

class _ChatAudioPlayerState extends State<ChatAudioPlayer> {
  late final Player _player = Player();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    _player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
      }
    });
  }

  Future<void> _initialize() async {
    try {
      await _player.open(Media(widget.source));
      await _player.setPlaylistMode(PlaylistMode.single);
    } catch (e) {
      debugPrint('Error initializing audio: ' + e.toString());
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: 150,
      height: 50,
      decoration: BoxDecoration(
        color: scheme.onSurface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
            onPressed: () => _player.playOrPause(),
          ),
          const Text('Audio'),
        ],
      ),
    );
  }
}

