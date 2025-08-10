import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import '../models/media_item.dart';
import '../services/media_prefetcher.dart';
import '../widgets/media/video_player_view.dart';
import '../widgets/report_bug_button.dart';

/// Displays a full‑screen gallery of media attachments.
class MediaViewer extends StatefulWidget {
  const MediaViewer({super.key, required this.media, this.initialIndex = 0});

  final List<MediaItem> media;
  final int initialIndex;

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late final PageController _controller;
  final MediaPrefetcher _prefetcher = const MediaPrefetcher();
  int _index = 0;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefetchAround(_index));
  }

  void _prefetchAround(int index) {
    if (index > 0) {
      _prefetcher.prefetch(context, widget.media[index - 1]);
    }
    if (index + 1 < widget.media.length) {
      _prefetcher.prefetch(context, widget.media[index + 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        _dragOffset += details.primaryDelta ?? 0;
        if (_dragOffset.abs() > 150) {
          Navigator.of(context).maybePop();
        }
      },
      onVerticalDragEnd: (_) => _dragOffset = 0,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.media.length,
              onPageChanged: (i) {
                setState(() => _index = i);
                _prefetchAround(i);
              },
              itemBuilder: (context, index) {
                final item = widget.media[index];
                final tag = item.fullUrl;
                switch (item.type) {
                  case MediaType.image:
                    return Hero(
                      tag: tag,
                      child: PhotoView(
                        imageProvider:
                            CachedNetworkImageProvider(item.fullUrl),
                        heroAttributes: PhotoViewHeroAttributes(tag: tag),
                      ),
                    );
                  case MediaType.video:
                    return Center(
                      child: Hero(
                        tag: tag,
                        child: VideoPlayerView(
                          url: Uri.parse(item.fullUrl),
                          autoplay: index == _index,
                        ),
                      ),
                    );
                }
              },
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  color: colorScheme.onSurface,
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: 'Close',
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.more_horiz),
                  color: colorScheme.onSurface,
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => SafeArea(
                        child: ReportBugButton(
                          child: const ListTile(
                            leading: Icon(Icons.bug_report_outlined),
                            title: Text('Report a Bug'),
                          ),
                        ),
                      ),
                    );
                  },
                  tooltip: 'More',
                ),
              ),
            ),
            Positioned(
              bottom: 24 + MediaQuery.of(context).padding.bottom,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${_index + 1} / ${widget.media.length}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: colorScheme.onSurface),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
