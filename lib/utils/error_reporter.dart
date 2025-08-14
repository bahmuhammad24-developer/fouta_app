import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:flutter/foundation.dart';

const bool _crashlyticsFlag = bool.fromEnvironment('CRASHLYTICS_ENABLED');

/// Centralized error reporting stub.
///
/// Logs the [error] with a timestamp. When [CRASHLYTICS_ENABLED] is true,
/// forwards errors to Firebase Crashlytics. Crashlytics calls are wrapped in
/// `try/catch` to avoid secondary failures if the plugin is misconfigured.

class ErrorReporter {
  ErrorReporter._();

  @visibleForTesting
  static FirebaseCrashlytics? crashlytics;

  @visibleForTesting
  static bool? crashlyticsEnabledOverride;

  static bool get _enabled =>
      crashlyticsEnabledOverride ?? _crashlyticsFlag;

  static FirebaseCrashlytics? get _instance {
    if (!_enabled) return null;
    return crashlytics ?? FirebaseCrashlytics.instance;
  }

  /// Report an [error] and optional [stackTrace].
  static void report(Object error, [StackTrace? stackTrace]) {
    final String ts = DateTime.now().toIso8601String();
    developer.log('[' + ts + '] ' + error.toString(), stackTrace: stackTrace);

    final FirebaseCrashlytics? c = _instance;
    if (c != null) {
      try {
        c.recordError(error, stackTrace);
      } catch (_) {
        // Swallow Crashlytics failures to avoid user-facing crashes.
      }

    }
  }
}
