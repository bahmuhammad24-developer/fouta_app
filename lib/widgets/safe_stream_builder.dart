import 'package:flutter/widgets.dart';

import 'package:fouta_app/utils/error_reporter.dart';
import 'package:fouta_app/widgets/error_state.dart';

/// A [StreamBuilder] wrapper that guards against build errors and stream
/// exceptions.
///
/// Example:
/// ```dart
/// import 'package:fouta_app/utils/json_safety.dart';
///
/// SafeStreamBuilder<Map<String, dynamic>>(
///   stream: stream,
///   builder: (context, snapshot) {
///     final count = asInt(snapshot.data?['count']);
///     return Text('$count');
///   },
/// );
/// ```
class SafeStreamBuilder<T> extends StatelessWidget {
  final Stream<T> stream;
  final AsyncWidgetBuilder<T> builder;
  final Widget? empty;
  final void Function(Object error, StackTrace? stackTrace)? onError;

  const SafeStreamBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.empty,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
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
