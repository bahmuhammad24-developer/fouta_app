import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/utils/app_flags.dart';
import 'package:fouta_app/utils/error_reporter.dart';

void main() {
  late ErrorRecorder originalRecorder;

  setUp(() {
    originalRecorder = errorRecorder;
    AppFlags.crashlyticsEnabled = false;
  });

  tearDown(() {
    errorRecorder = originalRecorder;
    AppFlags.crashlyticsEnabled = false;
  });

  test('forwards error to Crashlytics when enabled', () {
    AppFlags.crashlyticsEnabled = true;
    Object? seenError;
    StackTrace? seenStack;
    errorRecorder = (error, stack) async {
      seenError = error;
      seenStack = stack;
    };
    final err = Exception('boom');
    final st = StackTrace.current;
    ErrorReporter.report(err, st);
    expect(seenError, err);
    expect(seenStack, st);
  });

  test('no-op when disabled', () {
    AppFlags.crashlyticsEnabled = false;
    bool called = false;
    errorRecorder = (error, stack) async {
      called = true;
    };
    ErrorReporter.report(Exception('boom'));
    expect(called, false);
  });
}
