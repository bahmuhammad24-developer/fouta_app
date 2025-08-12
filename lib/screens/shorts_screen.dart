import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../features/shorts/shorts_service.dart';
import '../features/discovery/discovery_ranking_service.dart';

class ShortsScreen extends StatefulWidget {
  const ShortsScreen({super.key, ShortsService? service, DiscoveryRankingService? ranking})
      : _service = service,
        _ranking = ranking;

  final ShortsService? _service;
  final DiscoveryRankingService? _ranking;

  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  late final ShortsService _service = widget._service ?? ShortsService();
  late final DiscoveryRankingService _ranking =
      widget._ranking ?? DiscoveryRankingService();
  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _service.fetchShorts(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = _ranking.rank(snap.data!);
          return PageView.builder(
            controller: _controller,
            scrollDirection: Axis.vertical,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];
              final url = data['url'] as String?;
              return _ShortVideo(url: url);
            },
          );
        },
      ),
    );
  }
}

class _ShortVideo extends StatefulWidget {
  const _ShortVideo({required this.url});
  final String? url;

  @override
  State<_ShortVideo> createState() => _ShortVideoState();
}

class _ShortVideoState extends State<_ShortVideo> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.url != null) {
      _controller = VideoPlayerController.network(widget.url!)..initialize().then((_) {
          setState(() {});
          _controller?.play();
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 32,
          child: Column(
            children: [
              IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
              IconButton(icon: const Icon(Icons.comment), onPressed: () {}),
              IconButton(icon: const Icon(Icons.share), onPressed: () {}),
              IconButton(icon: const Icon(Icons.person_add), onPressed: () {}),
            ],
          ),
        ),
      ],
    );
  }
}
