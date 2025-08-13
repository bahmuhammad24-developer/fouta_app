import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:fouta_app/features/shorts/shorts_service.dart';
import 'package:fouta_app/utils/paging_controller.dart';
import 'package:fouta_app/widgets/animated_like_button.dart';
import 'package:fouta_app/widgets/refresh_scaffold.dart';
import 'package:fouta_app/widgets/safe_stream_builder.dart';
import 'package:fouta_app/widgets/video_player_widget.dart';
import 'package:fouta_app/theme/motion.dart';
import 'package:fouta_app/utils/error_reporter.dart';
import 'package:fouta_app/triggers/flags.dart';
import 'package:fouta_app/triggers/trigger_orchestrator.dart';
import 'package:fouta_app/widgets/triggers/keyword_filter_chips.dart';
import 'package:fouta_app/widgets/triggers/next_up_rail.dart';


class ShortsScreen extends StatelessWidget {
  ShortsScreen({super.key, ShortsService? service})

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

    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion ? AppDurations.fast : AppDurations.normal;

    return StreamBuilder<List<Short>>(
      stream: _service.streamShorts(),

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
        final showChips = TriggerOrchestrator.instance.fire(
          'keyword_chips',
          context: context,
          cap: 1,
          enabled: AppFlags.keywordChipsEnabled,
        );
        final showNext = TriggerOrchestrator.instance.fire(
          'next_up',
          context: context,
          cap: 1,
          enabled: AppFlags.nextUpEnabled,
        );
        return Scaffold(
          body: Stack(
            children: [
              AnimatedSwitcher(
                duration: duration,
                child: PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final short = items[index];
                    try {
                      final likeCount = short.likeIds.length;
                      Widget actionButton(IconData icon, VoidCallback onPressed) {
                        final button = IconButton(
                          icon: Icon(icon, color: Colors.white),
                          onPressed: onPressed,
                        );
                        return reduceMotion ? button : animateOnTap(child: button, onTap: onPressed);
                      }

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
                                actionButton(Icons.favorite, () {}),
                                Text('$likeCount',
                                    style: const TextStyle(color: Colors.white)),
                                const SizedBox(height: 16),
                                actionButton(Icons.comment, () {}),
                                const SizedBox(height: 16),
                                actionButton(Icons.share, () {}),
                                const SizedBox(height: 16),
                                actionButton(Icons.person_add, () {}),
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
              if (showChips)
                Positioned(
                  top: 40,
                  left: 0,
                  right: 0,
                  child: KeywordFilterChips(
                    keywords: const ['Music', 'Sports', 'News'],
                    onSelected: (_) {},
                  ),
                ),
              if (showNext)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: NextUpRail(
                    onSelected: (_) {},
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

