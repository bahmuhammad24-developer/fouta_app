/// Collects usage metrics and performance traces to guide product decisions.
import 'dart:async';

import 'package:flutter/foundation.dart';

/// Represents a single analytics event.
class AnalyticsEvent {
  final String name;
  final Map<String, Object?> parameters;

  const AnalyticsEvent(this.name, [this.parameters = const {}]);

  @override
  String toString() => 'AnalyticsEvent(name: $name, parameters: $parameters)';
}

/// Minimal analytics service that records events in memory and exposes a stream
/// for interested listeners. In a production environment these events would be
/// forwarded to an analytics backend and surfaced in dashboards.
class AnalyticsService {
  final _events = <AnalyticsEvent>[];
  final _controller = StreamController<AnalyticsEvent>.broadcast();

  /// Immutable view of recorded events.
  List<AnalyticsEvent> get events => List.unmodifiable(_events);

  /// Stream of events as they are logged.
  Stream<AnalyticsEvent> get eventsStream => _controller.stream;

  /// Record an event and notify listeners. Parameters are optional.
  void logEvent(String name, {Map<String, Object?>? parameters}) {
    final event = AnalyticsEvent(name, parameters ?? {});
    _events.add(event);
    _controller.add(event);
    debugPrint('Analytics: $event');
  }

  /// Dispose of resources.
  void dispose() {
    _controller.close();
  }
}
