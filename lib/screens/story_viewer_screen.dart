// lib/screens/story_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fouta_app/main.dart';
import 'package:fouta_app/models/story_model.dart';
import 'package:fouta_app/services/video_cache_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:fouta_app/utils/video_controller_extensions.dart';
import 'package:fouta_app/utils/date_utils.dart';
import 'package:fouta_app/utils/snackbar.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialStoryIndex;

  StoryViewerScreen({
    Key? key,
    required this.stories,
    required this.initialStoryIndex,
  }) : super(key: key ?? ValueKey(initialStoryIndex));

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  
  int _currentStoryIndex = 0;
  int _currentSlideIndex = 0;
  List<StorySlide> _slides = [];

  // Video playback support for story slides
  final VideoCacheService _cacheService = VideoCacheService();
  Player? _videoPlayer;
  VideoController? _videoController;
  StreamSubscription<Duration>? _videoPositionSubscription;
  bool _isCurrentSlideVideo = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _currentStoryIndex = widget.initialStoryIndex;
    _pageController = PageController(initialPage: _currentStoryIndex);
    _animationController = AnimationController(vsync: this);
    
    _loadSlidesForStory(_currentStoryIndex);

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.stop();
        _animationController.reset();
        _nextSlide();
      }
    });
  }
  
  void _loadSlidesForStory(int storyIndex) async {
    final story = widget.stories[storyIndex];
    final slidesSnapshot = await FirebaseFirestore.instance
      .collection('artifacts/$APP_ID/public/data/stories')
      .doc(story.userId)
      .collection('slides')
      .orderBy('createdAt')
      .get();
      
    final slides = slidesSnapshot.docs.map((doc) {
      final data = doc.data();
      return StorySlide(
        id: doc.id,
        url: data['mediaUrl'],
        mediaType: data['mediaType'],
        timestamp: data['createdAt'],
        viewers: data['viewers'] ?? [],
      );
    }).toList();

    setState(() {
      _currentStoryIndex = storyIndex;
      _currentSlideIndex = 0;
      _slides = slides;
    });

    // Mark story as viewed by current user
    _markStoryViewed(widget.stories[storyIndex].userId);

    await _playStorySlide();
  }

  Future<void> _playStorySlide() async {
    if (_slides.isEmpty) return;
    final StorySlide slide = _slides[_currentSlideIndex];
    // Record that the current user has viewed this slide
    _markSlideViewed(widget.stories[_currentStoryIndex].userId, slide);
    // Dispose previous video if the new slide is not a video
    if (_isCurrentSlideVideo && slide.mediaType != 'video') {
      _disposeVideo();
    }
    if (slide.mediaType == 'video') {
      _isCurrentSlideVideo = true;
      await _initializeVideo(slide);
    } else {
      _isCurrentSlideVideo = false;
      _disposeVideo();
      try {
        await precacheImage(CachedNetworkImageProvider(slide.url), context);
      } catch (_) {
        // Ignore precache errors and still advance
      }
      _animationController.duration = const Duration(seconds: 5);
      _animationController.forward(from: 0);
    }
  }

  void _nextSlide() {
    setState(() {
      if (_currentSlideIndex + 1 < _slides.length) {
        _currentSlideIndex++;
        unawaited(_playStorySlide());
      } else {
        _nextStory();
      }
    });
  }

  void _previousSlide() {
    setState(() {
      if (_currentSlideIndex - 1 >= 0) {
        _currentSlideIndex--;
        unawaited(_playStorySlide());
      } else {
        // If on the first slide, restart the timer
        unawaited(_playStorySlide());
      }
    });
  }

  void _restartCurrentSlide() {
    _animationController.stop();
    _animationController.reset();
    if (_isCurrentSlideVideo && _videoPlayer != null) {
      _videoPlayer!.seek(Duration.zero);
      _videoPlayer!.play();
    }
    _animationController.forward(from: 0);
  }
  
  void _nextStory() {
    if (_currentStoryIndex + 1 < widget.stories.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onTapUp(TapUpDetails details) {
    // Detect taps on the left or right half of the screen. Previously this
    // check used one third of the width, which sometimes caused a tap on
    // the left half to jump back an entire story. Using half of the
    // screen for navigation ensures that tapping on the left restarts or
    // moves to the previous slide and tapping on the right advances to
    // the next slide. This provides a more intuitive experience where
    // tapping the left half restarts the current clip rather than
    // restarting the entire story chain.
    final width = MediaQuery.of(context).size.width;
    if (details.globalPosition.dx < width / 2) {
      if (_animationController.value > 0.05) {
        _restartCurrentSlide();
      } else {
        _previousSlide();
      }
    } else {
      _nextSlide();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _disposeVideo();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  double _verticalDrag = 0;

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _verticalDrag += details.delta.dy;
      if (_verticalDrag < 0) _verticalDrag = 0;
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (_verticalDrag > 150) {
      setState(() => _verticalDrag = screenHeight);
      Future.delayed(const Duration(milliseconds: 200), () {
        Navigator.of(context).pop();
      });
    } else {
      setState(() => _verticalDrag = 0);
    }
  }

  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onVerticalDragUpdate: _handleVerticalDragUpdate,
      onVerticalDragEnd: _handleVerticalDragEnd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _verticalDrag, 0),
        child: Opacity(
          opacity: (1 - (_verticalDrag / 300)).clamp(0.0, 1.0),
          child: Scaffold(

            backgroundColor: Theme.of(context).colorScheme.onSurface,

            body: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                _animationController.stop();
                _animationController.reset();
                _loadSlidesForStory(index);
              },
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                if (index != _currentStoryIndex || _slides.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final Story currentStory = widget.stories[_currentStoryIndex];
                final StorySlide currentSlide = _slides[_currentSlideIndex];

            return GestureDetector(
              onTapUp: _onTapUp,
              onLongPressStart: (_) => _animationController.stop(),
              onLongPressEnd: (_) => _animationController.forward(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Display image or video based on media type
                  if (currentSlide.mediaType == 'video')
                    Center(
                      child: _videoController != null
                          ? Semantics(
                              label: 'Story video',
                              child: Video(
                                key: ValueKey(currentSlide.id),
                                controller: _videoController!,
                                fit: BoxFit.contain,
                              ),
                            )
                          : Center(
                              child: CircularProgressIndicator(

                                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),

                              ),
                            ),
                    )
                  else
                    Center(

                      child: CachedNetworkImage(
                        imageUrl: currentSlide.url,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),

                        errorWidget: (context, url, error) => Center(child: Icon(Icons.error, color: Theme.of(context).colorScheme.onPrimary)),

                      ),
                    ),
                  _buildOverlay(context, currentStory, currentSlide),
                ],
              ),
            );
          },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context, Story story, StorySlide slide) {
    return Positioned(
      top: 40.0,
      left: 10.0,
      right: 10.0,
      child: Column(
        children: [
          Row(
            children: _slides.asMap().entries.map((entry) {
              int index = entry.key;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: _currentSlideIndex == index
                      ? AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return LinearProgressIndicator(
                              value: _animationController.value,

                              backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.38),
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),

                            );
                          },
                        )
                      : LinearProgressIndicator(
                          value: _currentSlideIndex > index ? 1.0 : 0.0,

                          backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.38),
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),

                        ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: story.userImageUrl.isNotEmpty
                    ? NetworkImage(story.userImageUrl)
                    : null,
                child: story.userImageUrl.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 8.0),
              Text(
                story.userName,

                style: const TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,

                  fontWeight: FontWeight.bold,
                  shadows: const [Shadow(blurRadius: 2)],
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                DateUtilsHelper.formatRelative(slide.timestamp.toDate()),

                style: const TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,

                  fontSize: 12,
                  shadows: const [Shadow(blurRadius: 2)],
                ),
              ),
              const Spacer(),
              if (FirebaseAuth.instance.currentUser?.uid == story.userId)
                IconButton(

                  icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: () => _deleteStory(story.userId),
                ),
              IconButton(
                icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onPrimary),

                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Initialize video playback for a video story slide.
  Future<void> _initializeVideo(StorySlide slide) async {
    // Dispose any previously initialized video resources
    _disposeVideo();
    _videoPlayer = Player();
    try {
      final file = await _cacheService.getFile(slide.url);
      // `media_kit` needs a `file://` scheme to treat cached files as local.
      final uri = Uri.file(file.path).toString();
      await _videoPlayer!.open(Media(uri));
      final duration = _videoPlayer!.state.duration;
      final effectiveDuration = duration.inMilliseconds > 0
          ? duration
          : const Duration(seconds: 5);
      setState(() {
        _videoController = VideoController(_videoPlayer!);
      });
      _videoPlayer!.setPlaylistMode(PlaylistMode.single);
      await _videoPlayer!.play();
      // Mirror video length in the story progress bar only after playback starts
      _animationController.duration = effectiveDuration;
      _animationController.forward(from: 0);
      // Advance to next slide when video completes
      _videoPositionSubscription = _videoPlayer!.stream.position.listen((position) {
        final total = _videoPlayer!.state.duration;
        if (total.inMilliseconds > 0 && position >= total) {
          _nextSlide();
        }
      });
    } catch (e) {
      debugPrint('Error loading video slide: $e');
      // If video fails to load, fallback to a 5 second timer
      _animationController.duration = const Duration(seconds: 5);
      _animationController.forward(from: 0);
    }
  }

  /// Clean up video resources.
  void _disposeVideo() {
    _videoPositionSubscription?.cancel();
    _videoPositionSubscription = null;
    _videoController?.dispose();
    _videoController = null;
    _videoPlayer?.dispose();
    _videoPlayer = null;
  }

  /// Delete the current user's story from Firestore and storage.
  Future<void> _deleteStory(String userId) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Story'),
            content: const Text('Are you sure you want to delete your story?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldDelete) return;

    try {
      final storyRef = FirebaseFirestore.instance
          .collection('artifacts/$APP_ID/public/data/stories')
          .doc(userId);
      final slidesSnapshot = await storyRef.collection('slides').get();
      for (final doc in slidesSnapshot.docs) {
        final data = doc.data();
        final mediaUrl = data['mediaUrl'];
        if (mediaUrl is String && mediaUrl.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(mediaUrl).delete();
          } catch (_) {}
        }
        await doc.reference.delete();
      }
      await storyRef.delete();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Failed to delete story', isError: true);
      }
    }
  }

  /// Update the story document to record that the current user has viewed it.
  Future<void> _markStoryViewed(String userId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('artifacts/$APP_ID/public/data/stories')
          .doc(userId)
          .update({
        'viewedBy': FieldValue.arrayUnion([currentUser.uid])
      });
    } catch (_) {
      // Silently ignore errors (e.g. missing document)
    }
  }

  /// Update a slide document to record that the current user has viewed it.
  Future<void> _markSlideViewed(String storyUserId, StorySlide slide) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('artifacts/$APP_ID/public/data/stories')
          .doc(storyUserId)
          .collection('slides')
          .doc(slide.id)
          .update({
        'viewers': FieldValue.arrayUnion([currentUser.uid])
      });
    } catch (_) {
      // ignore errors
    }
  }
}
