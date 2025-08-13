import 'dart:developer' as developer;

/// Centralized error reporting stub.
///
/// Logs the [error] with a timestamp. Integration points for services
/// like Crashlytics or Sentry can be added later.
class ErrorReporter {
  /// Report an [error] and optional [stackTrace].
  static void report(Object error, [StackTrace? stackTrace]) {
    final String ts = DateTime.now().toIso8601String();
    developer.log('[' + ts + '] ' + error.toString(), stackTrace: stackTrace);
    // TODO: Hook into Crashlytics or Sentry.
  }
}
