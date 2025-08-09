import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:fouta_app/services/video_cache_service.dart';
import 'package:fouta_app/utils/video_controller_extensions.dart';

/// A unified full‑screen media viewer that can display a list of images and
/// videos.  Users can swipe between items, pinch to zoom on photos, and
/// tap to toggle controls on videos.  This widget replaces the separate
/// full‑screen image and video players with a single, cohesive experience.
///
/// Each media item must be represented as a map containing at least a
/// `url` and a `type` key.  The `type` should be either `'image'` or
/// `'video'`.  An optional `aspectRatio` can be provided for videos to
/// preserve their dimensions.
class MediaViewer extends StatefulWidget {
  final List<Map<String, dynamic>> mediaList;
  final int initialIndex;

  const MediaViewer({super.key, required this.mediaList, this.initialIndex = 0});

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
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
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.mediaList.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final media = widget.mediaList[index];
                final String type = media['type'] ?? 'image';
                final String url = media['url'] ?? '';
                final String previewUrl = media['previewUrl'] ?? url;
                final String blurhash = media['blurhash'] ?? '';
                final double? aspectRatio = media['aspectRatio'] as double?;
                return _MediaFilePage(
                  key: ValueKey(url),
                  url: url,
                  type: type,
                  aspectRatio: aspectRatio,
                  previewUrl: previewUrl,
                  blurhash: blurhash,
                );
              },
            ),
            // Page indicator at the bottom when multiple media items are present
            if (widget.mediaList.length > 1)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.mediaList.length, (index) {
                    final bool isActive = index == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 12 : 8,
                      height: isActive ? 12 : 8,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A single page within the [MediaViewer].  Displays either an image or a
/// video.  Videos are automatically cached and played with simple controls.
class _MediaFilePage extends StatefulWidget {
  final String url;
  final String previewUrl;
  final String blurhash;
  final String type;
  final double? aspectRatio;

  _MediaFilePage({
    Key? key,
    required this.url,
    required this.type,
    this.aspectRatio,
    required this.previewUrl,
    required this.blurhash,
  }) : super(key: key ?? ValueKey(url));

  @override
  State<_MediaFilePage> createState() => _MediaFilePageState();
}

class _MediaFilePageState extends State<_MediaFilePage> {
  final VideoCacheService _cacheService = VideoCacheService();
  Player? _player;
  VideoController? _controller;
  bool _isVideoInitialized = false;
  bool _showControls = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'video') {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    setState(() => _isLoading = true);
    final player = Player();
    try {
      final file = await _cacheService.getFile(widget.url);
      // Using `file://` prevents media_kit from treating the path as remote.
      final uri = Uri.file(file.path).toString();
      await player.open(Media(uri), play: true);
      if (!mounted) return;
      setState(() {
        _player = player;
        _controller = VideoController(player);
        _isVideoInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading video in MediaViewer: $e');
      await player.dispose();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not play video.')));
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == 'image') {
      return Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: widget.url,
            fit: BoxFit.contain,
            placeholder: (context, url) => CachedNetworkImage(
              imageUrl: widget.previewUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => BlurHash(
                hash: widget.blurhash,
                imageFit: BoxFit.contain,
              ),
              errorWidget: (c, u, e) => Container(color: Colors.black),
            ),
            errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, color: Colors.white)),
          ),
        ),
      );
    }
    // Video case
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (!_isVideoInitialized || _controller == null) {
      return const Center(child: Text('Error loading video.', style: TextStyle(color: Colors.white)));
    }
    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: widget.aspectRatio ?? 16 / 9,
            child: Video(
              key: ValueKey(widget.url),
              controller: _controller!,
              controls: AdaptiveVideoControls,
            ),
          ),
          if (_showControls)
            Positioned(
              bottom: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _player!.state.playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      color: Colors.white,
                      size: 48,
                    ),
                    onPressed: () {
                      if (_player!.state.playing) {
                        _player!.pause();
                      } else {
                        _player!.play();
                      }
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}