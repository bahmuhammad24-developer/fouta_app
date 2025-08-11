import 'package:flutter/material.dart';
import 'playback_coordinator.dart';

class PlaybackRouteObserver extends NavigatorObserver {
  void _pauseAll() {
    try { PlaybackCoordinator.instance.pauseAll(); } catch (_) {}
  }
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _pauseAll();
  }
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _pauseAll();
  }
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _pauseAll();
  }
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _pauseAll();
  }
}
