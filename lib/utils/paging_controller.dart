import 'package:flutter/widgets.dart';

/// Controller that triggers [onLoadMore] when the user scrolls near the bottom.
class PagingController {
  final Future<void> Function() onLoadMore;
  final double threshold;
  final ScrollController scrollController;

  bool _loading = false;
  bool _triggered = false;

  PagingController({
    required this.onLoadMore,
    this.threshold = 200,
    ScrollController? scrollController,
  }) : scrollController = scrollController ?? ScrollController() {
    this.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final position = scrollController.position;
    if (!_loading && !_triggered && position.extentAfter < threshold) {
      _loading = true;
      _triggered = true;
      onLoadMore().whenComplete(() => _loading = false);
    }
  }

  /// Allows another load once new data has been appended.
  void reset() {
    _triggered = false;
  }

  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
  }
}
