import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:photo_view/photo_view.dart';

import '../models/media_item.dart';
import 'report_bug_screen.dart';

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
  bool _showChrome = true;
  late final Player _player = Player();
  late final VideoController _videoController = VideoController(_player);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    final item = widget.items[widget.initialIndex];
    _player.open(Media(item.url), play: true);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _player.dispose(); // Dispose player
    super.dispose();
  }

  void _toggleChrome() => setState(() => _showChrome = !_showChrome);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _openIndex,
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final item = widget.items[index];
          return Hero(
            tag: 'media-${item.id}',
            child: _buildItem(item),
          );
        },
      ),
    );
  }

  Widget _buildItem(MediaItem item) {
    switch (item.type) {
      case MediaType.image:
        return GestureDetector(
          onTap: _toggleChrome,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PhotoView(
                imageProvider: CachedNetworkImageProvider(item.url),
                backgroundDecoration: const BoxDecoration(color: Colors.black),
              ),
              _buildOverlay(),
            ],
          ),
        );
      case MediaType.video:
        return GestureDetector(
          onTap: _toggleChrome,
          onLongPress: () {
            final rate = _player.state.rate == 1.0 ? 2.0 : 1.0;
            _player.setRate(rate);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Video(controller: _videoController, fit: BoxFit.contain),
              _buildOverlay(),
            ],
          ),
        );
    }
  }

  void _openIndex(int index) {
    final item = widget.items[index];
    _player.open(Media(item.url), play: true);
  }

  Widget _buildOverlay() {
    return IgnorePointer(
      ignoring: !_showChrome,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _showChrome ? 1.0 : 0.0,
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            color: Colors.black.withOpacity(0.45),
            child: SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: Text('Report a Bug'),
                    ),
                  ],
                  onSelected: (v) {
                    if (v == 'report') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportBugScreen()),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

