import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:photo_view/photo_view.dart';

import '../models/media_item.dart';

/// Full-screen viewer for a list of [MediaItem]s.
class FullScreenMediaViewer extends StatefulWidget {
  const FullScreenMediaViewer({super.key, required this.items, this.initialIndex = 0});

  final List<MediaItem> items;
  final int initialIndex;

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer> {
  late final PageController _pageController;
  bool _showUi = true;
  final Map<int, Player> _players = {};
  final Map<int, VideoController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final player in _players.values) {
      player.dispose();
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleUi() => setState(() => _showUi = !_showUi);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final item = widget.items[index];
          return Hero(
            tag: 'media-${item.id}',
            child: _buildItem(item, index),
          );
        },
      ),
    );
  }

  Widget _buildItem(MediaItem item, int index) {
    switch (item.type) {
      case MediaType.image:
        return GestureDetector(
          onTap: _toggleUi,
          child: PhotoView(
            imageProvider: CachedNetworkImageProvider(item.url),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        );
      case MediaType.video:
        final player = _players[index] ?? Player();
        _players[index] = player;
        final controller = _controllers[index] ?? VideoController(player);
        _controllers[index] = controller;
        if (player.state.media?.uri != item.url) {
          player.open(Media(item.url));
        }
        return GestureDetector(
          onTap: _toggleUi,
          onLongPress: () {
            final rate = player.state.rate == 1.0 ? 2.0 : 1.0;
            player.setRate(rate);
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Video(controller: controller, fit: BoxFit.contain),
              if (_showUi) _buildVideoOverlay(player),
            ],
          ),
        );
    }
  }

  Widget _buildVideoOverlay(Player player) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: IconButton(
                iconSize: 64,
                color: Colors.white,
                icon: StreamBuilder<bool>(
                  stream: player.stream.playing,
                  builder: (context, snapshot) {
                    final playing = snapshot.data ?? false;
                    return Icon(playing ? Icons.pause_circle : Icons.play_circle);
                  },
                ),
                onPressed: player.playOrPause,
              ),
            ),
          ),
          StreamBuilder<Duration>(
            stream: player.stream.position,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = player.state.duration;
              double value = 0.0;
              if (duration.inMilliseconds > 0) {
                value = position.inMilliseconds / duration.inMilliseconds;
              }
              return Slider(
                value: value.clamp(0.0, 1.0),
                onChanged: (v) => player.seek(duration * v),
              );
            },
          ),
        ],
      ),
    );
  }
}

