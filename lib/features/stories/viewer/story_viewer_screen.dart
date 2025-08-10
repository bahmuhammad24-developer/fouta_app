import 'package:flutter/material.dart';

import '../../../models/story.dart';
import '../../../models/media_item.dart';
import '../data/story_repository.dart';
import 'package:flutter/services.dart';

/// Full-screen viewer for stories with basic gestures.
class StoryViewerScreen extends StatefulWidget {
  final List<Story> stories;
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
  late PageController _storyController;
  late AnimationController _progress;
  final StoryRepository _repo = StoryRepository();

  int _storyIndex = 0;
  int _itemIndex = 0;

  @override
  void initState() {
    super.initState();
    _storyIndex = widget.initialIndex;
    _storyController = PageController(initialPage: _storyIndex);
    _progress = AnimationController(vsync: this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _startCurrent();
  }

  @override
  void dispose() {
    _progress.dispose();
    _storyController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _startCurrent() {
    final story = widget.stories[_storyIndex];
    final item = story.items[_itemIndex];
    _progress
      ..duration = _slideDuration(item)
      ..forward(from: 0)
      ..addStatusListener(_handleStatus);
    _repo.markViewed(story.authorId, item.media.id);
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _nextItem();
    }
  }

  Duration _slideDuration(StoryItem item) {
    // Prefer an explicit duration on the slide/media; fallback to 6s for images.
    final d = item.media.duration;
    if (d != null) return d;
    return item.media.type == MediaType.video
        ? const Duration(seconds: 15) // safety cap if unknown
        : const Duration(seconds: 6);
  }

  void _nextItem() {
    _progress.removeStatusListener(_handleStatus);
    final story = widget.stories[_storyIndex];
    if (_itemIndex < story.items.length - 1) {
      setState(() => _itemIndex++);
      _startCurrent();
    } else if (_storyIndex < widget.stories.length - 1) {
      _storyController.nextPage(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _prevItem() {
    _progress.removeStatusListener(_handleStatus);
    if (_itemIndex > 0) {
      setState(() => _itemIndex--);
      _startCurrent();
    } else if (_storyIndex > 0) {
      _storyController.previousPage(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPressStart: (_) => _progress.stop(),
        onLongPressEnd: (_) => _progress.forward(),
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 2) {
            _prevItem();
          } else {
            _nextItem();
          }
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 500) {
            Navigator.of(context).maybePop();
          }
        },
        child: PageView.builder(
          controller: _storyController,
          onPageChanged: (index) {
            setState(() {
              _storyIndex = index;
              _itemIndex = 0;
            });
            _startCurrent();
          },
          itemCount: widget.stories.length,
          itemBuilder: (context, index) {
            final story = widget.stories[index];
            return _buildStory(story);
          },
        ),
      ),
    );
  }

  Widget _buildStory(Story story) {
    final item = story.items[_itemIndex];
    final cs = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          item.media.url,
          fit: BoxFit.cover,
        ),
        Positioned(
          top: 40,
          left: 16,
          right: 16,
          child: AnimatedBuilder(
            animation: _progress,
            builder: (context, _) {
              return LinearProgressIndicator(
                value: _progress.value,
                backgroundColor: cs.surface.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              );
            },
          ),
        ),
      ],
    );
  }
}
