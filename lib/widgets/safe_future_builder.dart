import 'package:flutter/widgets.dart';

import 'package:fouta_app/utils/error_reporter.dart';
import 'package:fouta_app/widgets/error_state.dart';

/// A [FutureBuilder] wrapper that guards against build errors and future
/// exceptions.
///
/// Example:
/// ```dart
/// import 'package:fouta_app/utils/json_safety.dart';
///
/// SafeFutureBuilder<Map<String, dynamic>>(
///   future: fetch(),
///   builder: (context, snapshot) {
///     final count = asInt(snapshot.data?['count']);
///     return Text('$count');
///   },
/// );
/// ```
class SafeFutureBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final AsyncWidgetBuilder<T> builder;
  final Widget? empty;
  final void Function(Object error, StackTrace? stackTrace)? onError;

  const SafeFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.empty,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          onError?.call(snapshot.error!, snapshot.stackTrace);
          ErrorReporter.report(snapshot.error!, snapshot.stackTrace);
          return const ErrorState();
        }
        if (!snapshot.hasData) {
          return empty ?? const SizedBox.shrink();
        }
        try {
          return builder(context, snapshot);
        } catch (e, st) {
          onError?.call(e, st);
          ErrorReporter.report(e, st);
          return const ErrorState();
        }
      },
    );
  }
}
