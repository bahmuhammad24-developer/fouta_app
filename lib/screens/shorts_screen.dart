import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:fouta_app/features/shorts/shorts_service.dart';
import 'package:fouta_app/utils/paging_controller.dart';
import 'package:fouta_app/widgets/animated_like_button.dart';
import 'package:fouta_app/widgets/refresh_scaffold.dart';
import 'package:fouta_app/widgets/safe_stream_builder.dart';
import 'package:fouta_app/widgets/video_player_widget.dart';
import 'package:fouta_app/utils/error_reporter.dart';

class ShortsScreen extends StatefulWidget {
  ShortsScreen({super.key, ShortsService? service, this.onLoadMore})
      : _service = service ?? ShortsService();

  final ShortsService _service;
  final Future<void> Function()? onLoadMore;

  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  late final PagingController _paging;

  @override
  void initState() {
    super.initState();
    _paging = PagingController(
      onLoadMore: widget.onLoadMore ?? () => widget._service.streamShorts().first,
      scrollController: PageController(),
    );
  }

  @override
  void dispose() {
    _paging.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    await widget._service.streamShorts().first;
    _paging.reset();
  }

  @override
  Widget build(BuildContext context) {
    return SafeStreamBuilder<List<Short>>(
      stream: widget._service.streamShorts(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No shorts yet'),
                ),
              ),
            ),
          );
        }
        return Scaffold(
          body: RefreshScaffold(
            onRefresh: _reload,
            slivers: [
              SliverFillRemaining(
                child: PageView.builder(
                  controller: _paging.scrollController as PageController,
                  scrollDirection: Axis.vertical,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final short = items[index];
                    final likeCount = short.likeIds.length;
                    try {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          VideoPlayerWidget(
                            videoUrl: short.url,
                            videoId: short.id,
                            aspectRatio: short.aspectRatio,
                            areControlsVisible: false,
                            shouldInitialize: true,
                          ),

                          Positioned(
                            right: 16,
                            bottom: 80,
                            child: Column(
                              children: [
                                AnimatedLikeButton(
                                  isLiked: false,
                                  onChanged: (_) {},
                                ),
                                Text('$likeCount',
                                    style: const TextStyle(color: Colors.white)),
                                const SizedBox(height: 16),
                                IconButton(
                                  icon: const Icon(Icons.comment,
                                      color: Colors.white),
                                  onPressed: () {},
                                ),
                                const SizedBox(height: 16),
                                IconButton(
                                  icon: const Icon(Icons.share,
                                      color: Colors.white),
                                  onPressed: () {},
                                ),
                                const SizedBox(height: 16),
                                IconButton(
                                  icon: const Icon(Icons.person_add,
                                      color: Colors.white),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    } catch (e, st) {
                      debugPrint('Error rendering short ${short.id}: $e');
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ),
            ],

          ),
        );
      },
    );
  }
}

