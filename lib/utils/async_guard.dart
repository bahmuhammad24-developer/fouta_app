import 'package:flutter/widgets.dart';

import 'package:fouta_app/utils/error_reporter.dart';

/// Guards state updates to run only when the [State] is still mounted.
void mountedSetState(State state, VoidCallback fn) {
  if (!state.mounted) return;
  state.setState(fn);
}

/// Runs [op] and reports any thrown errors.
///
/// If an error occurs, it is reported and rethrown. Optionally, an [onError]
/// callback can handle the error before it is rethrown.
Future<T> guardAsync<T>(Future<T> Function() op,
    {Function(Object, StackTrace)? onError}) async {
  try {
    return await op();
  } catch (e, st) {
    ErrorReporter.report(e, st);
    if (onError != null) onError(e, st);
    rethrow;
  }
}
