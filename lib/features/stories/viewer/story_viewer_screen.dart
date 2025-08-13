import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../stories_service.dart';
import '../../creation/editor/overlays/overlay_models.dart';
import 'package:fouta_app/triggers/flags.dart';
import 'package:fouta_app/triggers/trigger_orchestrator.dart';
import 'package:fouta_app/widgets/triggers/story_inline_reply_chip.dart';

/// Viewer for playing a sequence of stories with basic controls and overlays.
class StoryViewerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with TickerProviderStateMixin {
  late PageController _controller;
  late AnimationController _progress;
  int _index = 0;
  final _marked = <String>{};
  VideoPlayerController? _video;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
    _progress = AnimationController(vsync: this)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _next();
      });
    _loadCurrent();
  }

  @override
  void dispose() {
    _video?.dispose();
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _loadCurrent() {
    _video?.dispose();
    final story = widget.stories[_index];
    if (story['mediaType'] == 'video') {
      _video = VideoPlayerController.network(story['mediaUrl'])
        ..initialize().then((_) {
          setState(() {});
          _video?.play();
        });
    } else {
      _video = null;
    }

    final duration = story['mediaType'] == 'video'
        ? (_video?.value.duration ?? const Duration(seconds: 15))
        : const Duration(seconds: 6);
    _progress
      ..duration = duration
      ..forward(from: 0);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && !_marked.contains(story['id'])) {
      StoriesService().markViewed(storyId: story['id'], userId: uid);
      _marked.add(story['id']);
    }
  }

  void _pause() {
    _progress.stop();
    _video?.pause();
  }

  void _resume() {
    _progress.forward();
    if (_video != null && _video!.value.isInitialized) _video!.play();
  }

  void _next() {
    if (_index < widget.stories.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _prev() {
    if (_index > 0) {
      _controller.previousPage(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        onTapUp: (d) {
          final w = MediaQuery.of(context).size.width;
          if (d.globalPosition.dx < w / 2) {
            _prev();
          } else {
            _next();
          }
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              onPageChanged: (i) {
                setState(() => _index = i);
                _loadCurrent();
              },
              itemCount: widget.stories.length,
              itemBuilder: (context, i) => _buildStory(widget.stories[i]),
            ),
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: Row(
                children: List.generate(widget.stories.length, (i) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: AnimatedBuilder(
                        animation: _progress,
                        builder: (context, _) {
                          double value;
                          if (i < _index) {
                            value = 1;
                          } else if (i == _index) {
                            value = _progress.value;
                          } else {
                            value = 0;
                          }
                          return LinearProgressIndicator(
                            key: ValueKey('progress_$i'),
                            value: value,
                            backgroundColor: Colors.white24,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(Colors.white),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
            ),
            if (TriggerOrchestrator.instance.fire(
              id: 'story_reply_chip',
              enabled: AppFlags.storyReplyChipEnabled,
              perSessionCap: 1,
            ))
              StoryInlineReplyChip(onTap: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildStory(Map<String, dynamic> story) {
    final type = story['mediaType'];
    Widget media;
    if (type == 'video') {
      media = _video != null && _video!.value.isInitialized
          ? FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                  width: _video!.value.size.width,
                  height: _video!.value.size.height,
                  child: VideoPlayer(_video!)))
          : const SizedBox.shrink();
    } else {
      media = Image.network(story['mediaUrl'], fit: BoxFit.cover);
    }

    final overlays = (story['overlays'] as List?)
            ?.whereType<Map>()
            .map((e) => OverlayModel.fromMap(e.cast<String, dynamic>()))
            .toList() ??
        const [];

    return Stack(
      fit: StackFit.expand,
      children: [
        media,
        ...overlays.map(_overlayWidget),
      ],
    );
  }

  Widget _overlayWidget(OverlayModel o) {
    Widget child;
    if (o is TextOverlay) {
      child = Text(o.text,
          style: TextStyle(color: Color(o.color), fontSize: o.fontSize));
    } else if (o is StickerOverlay) {
      child = Text(o.emoji, style: const TextStyle(fontSize: 48));
    } else if (o is ShapeOverlay) {
      child = Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Color(o.color).withOpacity(o.opacity),
          shape: o.shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
        ),
      );
    } else {
      child = const SizedBox();
    }
    return Positioned(
      left: o.dx,
      top: o.dy,
      child: Transform.rotate(
        angle: o.rotation,
        child: Transform.scale(
          scale: o.scale,
          child: Opacity(opacity: o.opacity, child: child),
        ),
      ),
    );
  }
}

