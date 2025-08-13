import 'package:flutter/widgets.dart';

class TriggerOrchestrator {
  TriggerOrchestrator._();
  static final TriggerOrchestrator instance = TriggerOrchestrator._();

  final Map<String, int> _hits = {};

  void hit(String id) {
    _hits[id] = (_hits[id] ?? 0) + 1;
  }

  bool canFire(String id, {int cap = 3}) {
    return (_hits[id] ?? 0) < cap;
  }

  bool fire(
    String id, {
    required BuildContext context,
    required int cap,
    required bool enabled,
  }) {
    if (!enabled || !canFire(id, cap: cap)) return false;
    hit(id);
    return true;
  }
}

bool shouldShowNextUp({double completedRatio = 0}) => completedRatio >= 0.9;
bool shouldShowKeywordChips({double? dwell}) => (dwell ?? 0) < 0.3;
bool shouldShowFriendsFirst({int unseenCount = 0}) => unseenCount > 0;
bool shouldShowStoryReply({bool replied = false}) => !replied;
