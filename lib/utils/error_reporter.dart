import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'app_flags.dart';

typedef ErrorRecorder = Future<void> Function(Object error, StackTrace? stackTrace);

ErrorRecorder errorRecorder =
    (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack);

/// Centralized error reporting.
///
/// Logs the [error] with a timestamp and forwards to Crashlytics when
/// `AppFlags.crashlyticsEnabled` is true.
class ErrorReporter {
  /// Report an [error] and optional [stackTrace].
  static void report(Object error, [StackTrace? stackTrace]) {
    final String ts = DateTime.now().toIso8601String();
    developer.log('[' + ts + '] ' + error.toString(), stackTrace: stackTrace);
    if (AppFlags.crashlyticsEnabled) {
      // Only forward error strings and stack traces to avoid sensitive data.
      unawaited(errorRecorder(error, stackTrace));
    }
  }
}
