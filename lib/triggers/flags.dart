// lib/triggers/flags.dart
// Simple, in-repo feature flags. Replace with Remote Config when ready.

class AppFlags {
  // --- Triggers ---
  static bool get nextUpEnabled => true;
  static bool get keywordChipsEnabled => true;
  static bool get friendsFirstEnabled => true;
  static bool get storyReplyChipEnabled => true;

  // --- Ranking ---
  // 'v1' keeps current behavior; switch to 'v2' to try DiscoveryRankingV2.
  static String get feedRanking => 'v1';

  // --- Caps (soft defaults; can be tuned remotely later) ---
  static int get capNextUpPerSession => 3;
  static int get capKeywordChipsPerSession => 5;
  static int get capFriendsFirstPerSession => 2;
  static int get capStoryReplyChipPerSession => 8;

  // --- Cooldowns (minutes) ---
  static int get cooldownNextUpMinutes => 30;
  static int get cooldownKeywordChipsMinutes => 15;
  static int get cooldownFriendsFirstMinutes => 60;
  static int get cooldownStoryReplyChipMinutes => 0;
}
