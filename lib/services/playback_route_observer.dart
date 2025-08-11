import 'package:flutter/material.dart';
import 'playback_coordinator.dart';

class PlaybackRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  void _pauseAll() {
    try {
      PlaybackCoordinator.instance.pauseAll();
    } catch (_) {}
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _pauseAll();
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _pauseAll();
  }

  @override
  void didPushNext(Route nextRoute, Route route) {
    _pauseAll();
  }

  @override
  void didPopNext(Route nextRoute, Route route) {
    _pauseAll();
  }
}
