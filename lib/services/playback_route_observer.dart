import 'package:flutter/material.dart';

import 'playback_coordinator.dart';

/// Route observer that pauses all media players whenever a new page is pushed
/// or when returning to a previous page.
class PlaybackRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  void _pauseAll() => PlaybackCoordinator.instance.pauseAll();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) _pauseAll();
  }

  @override
  void didPopNext(Route<dynamic> nextRoute, Route<dynamic>? previousRoute) {
    super.didPopNext(nextRoute, previousRoute);
    if (nextRoute is PageRoute) _pauseAll();
  }
}

/// Global instance used by [MaterialApp.navigatorObservers].
final playbackRouteObserver = PlaybackRouteObserver();

