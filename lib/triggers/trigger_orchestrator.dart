// lib/triggers/trigger_orchestrator.dart
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'flags.dart';

/// In-memory session caps + simple eligibility helpers.
/// You decide *where* to call these from (e.g., after video complete, when dwell dips).
class TriggerOrchestrator {
  TriggerOrchestrator._();
  static final TriggerOrchestrator instance = TriggerOrchestrator._();

  final Map<String, int> _hits = HashMap<String, int>();
  final Map<String, DateTime> _lastShownAt = HashMap<String, DateTime>();

  void resetSession() {
    _hits.clear();
    _lastShownAt.clear();
  }

  bool _withinCap(String id, int cap) => (_hits[id] ?? 0) < cap;

  bool _cooldownPassed(String id, Duration cooldown) {
    final last = _lastShownAt[id];
    if (last == null) return true;
    return DateTime.now().difference(last) >= cooldown;
  }

  void _markFired(String id) {
    _hits[id] = (_hits[id] ?? 0) + 1;
    _lastShownAt[id] = DateTime.now();
  }

  /// Generic fire gate.
  /// Returns true when the trigger may be rendered now.
  bool tryFire({
    required String id,
    required bool enabled,
    required int perSessionCap,
    Duration cooldown = Duration.zero,
    bool eligibility = true,
  }) {
    if (!enabled) return false;
    if (!eligibility) return false;
    if (!_withinCap(id, perSessionCap)) return false;
    if (!_cooldownPassed(id, cooldown)) return false;
    _markFired(id);
    return true;
  }

  /// Alias for [tryFire] to support legacy call sites.
  bool fire({
    required String id,
    required bool enabled,
    required int perSessionCap,
    Duration cooldown = Duration.zero,
    bool eligibility = true,
  }) {
    return tryFire(
      id: id,
      enabled: enabled,
      perSessionCap: perSessionCap,
      cooldown: cooldown,
      eligibility: eligibility,
    );
  }

  // ---------------- Eligibility helpers ----------------

  /// Show Next-Up rail when user watched most of a short/video.
  bool shouldShowNextUp({
    required double completedRatio, // 0.0 - 1.0
    int minCompletes = 1,
  }) {
    return completedRatio >= 0.9; // simple, tune later
  }

  /// Show keyword chips if dwell (time since last interaction) grows.
  bool shouldShowKeywordChips({
    required Duration dwellSinceLastAction,
    Duration threshold = const Duration(seconds: 8),
  }) {
    return dwellSinceLastAction >= threshold;
  }

  /// Friends-first header if close ties posted recently.
  bool shouldShowFriendsFirst({
    required int closeTieNewPosts, // fetched via your service
    int minNewPosts = 1,
  }) {
    return closeTieNewPosts >= minNewPosts;
  }

  /// Story reply chip is generally safe to show (can be contextual).
  bool shouldShowStoryReplyChip() => true;
}
