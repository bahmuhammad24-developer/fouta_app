import 'package:fouta_app/utils/error_reporter.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCrashlytics implements FirebaseCrashlytics {
  Object? error;
  StackTrace? stack;
  @override
  Future<void> recordError(dynamic exception, StackTrace? stack,
      {dynamic reason,
      Iterable<dynamic> information = const [],
      bool fatal = false}) async {
    error = exception;
    this.stack = stack;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    ErrorReporter.crashlytics = null;
    ErrorReporter.crashlyticsEnabledOverride = null;
  });

  test('forwards to Crashlytics when enabled', () {
    final fake = _FakeCrashlytics();
    ErrorReporter.crashlytics = fake;
    ErrorReporter.crashlyticsEnabledOverride = true;
    final st = StackTrace.current;
    ErrorReporter.report('boom', st);
    expect(fake.error, 'boom');
    expect(fake.stack, st);
  });

  test('suppresses Crashlytics when disabled', () {
    final fake = _FakeCrashlytics();
    ErrorReporter.crashlytics = fake;
    ErrorReporter.crashlyticsEnabledOverride = false;
    ErrorReporter.report('oops');
    expect(fake.error, isNull);
  });
}
