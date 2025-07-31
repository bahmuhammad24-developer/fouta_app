// lib/screens/story_viewer_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fouta_app/main.dart';
import 'package:fouta_app/models/story_model.dart';
import 'package:fouta_app/services/video_cache_service.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialStoryIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.initialStoryIndex,
  });

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

    _playStorySlide();
  }

  void _playStorySlide() {
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
      _initializeVideo(slide);
    } else {
      _isCurrentSlideVideo = false;
      _disposeVideo();
      _animationController.duration = const Duration(seconds: 5);
      _animationController.forward(from: 0);
    }
  }

  void _nextSlide() {
    setState(() {
      if (_currentSlideIndex + 1 < _slides.length) {
        _currentSlideIndex++;
        _playStorySlide();
      } else {
        _nextStory();
      }
    });
  }

  void _previousSlide() {
    setState(() {
      if (_currentSlideIndex - 1 >= 0) {
        _currentSlideIndex--;
        _playStorySlide();
      } else {
        // If on the first slide, restart the timer
        _playStorySlide();
      }
    });
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
    final width = MediaQuery.of(context).size.width;
    if (details.globalPosition.dx < width / 3) {
      _previousSlide();
    } else {
      _nextSlide();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Wrapped the body in a Dismissible for swipe-down-to-close functionality
    return Dismissible(
      key: const Key('story_viewer'),
      direction: DismissDirection.down,
      onDismissed: (_) => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black,
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
                          ? Video(
                              controller: _videoController!,
                              fit: BoxFit.contain,
                            )
                          : const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                    )
                  else
                    Center(
                      child: CachedNetworkImage(
                        imageUrl: currentSlide.url,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Center(child: Icon(Icons.error, color: Colors.white)),
                      ),
                    ),
                  _buildOverlay(context, currentStory),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context, Story story) {
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
                              backgroundColor: Colors.white38,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            );
                          },
                        )
                      : LinearProgressIndicator(
                          value: _currentSlideIndex > index ? 1.0 : 0.0,
                          backgroundColor: Colors.white38,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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
                backgroundImage: story.userImageUrl.isNotEmpty ? NetworkImage(story.userImageUrl) : null,
                child: story.userImageUrl.isEmpty ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 8.0),
              Text(story.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2)])),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
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
      await _videoPlayer!.open(Media(file.path));
      final duration = _videoPlayer!.state.duration;
      final effectiveDuration = duration.inMilliseconds > 0
          ? duration
          : const Duration(seconds: 5);
      setState(() {
        _videoController = VideoController(_videoPlayer!);
      });
      _videoPlayer!.setPlaylistMode(PlaylistMode.single);
      _videoPlayer!.play();
      // Mirror video length in the story progress bar
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
    // Avoid duplicate writes if user already in viewers list
    if (slide.viewers.contains(currentUser.uid)) return;
    try {
      await FirebaseFirestore.instance
          .collection('artifacts/$APP_ID/public/data/stories')
          .doc(storyUserId)
          .collection('slides')
          .doc(slide.id)
          .update({
        'viewers': FieldValue.arrayUnion([currentUser.uid])
      });
      // Update local state to include this viewer
      slide.viewers.add(currentUser.uid);
    } catch (_) {
      // ignore errors
    }
  }
}

extension on VideoController? {
  void dispose() {}
}