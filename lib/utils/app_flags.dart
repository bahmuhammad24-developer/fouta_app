// lib/utils/app_flags.dart
/// Centralized feature flags for runtime gating.
class AppFlags {
  AppFlags._();

  /// Feed ranking strategy. Defaults to 'v1'.
  static String feedRanking = 'v1';

  /// Navigation variant flag. Defaults to 'v1'.
  static String navVariant = 'v1';
}
