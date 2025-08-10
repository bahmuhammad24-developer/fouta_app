import 'package:flutter/foundation.dart';

/// A simple ring buffer that captures the last 200 debugPrint lines.
class LogBuffer {
  LogBuffer._();
  static final LogBuffer instance = LogBuffer._();

  final List<String> _lines = <String>[];

  /// Wraps [debugPrint] to capture log lines. Call once before runApp.
  void init() {
    final original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        if (_lines.length >= 200) {
          _lines.removeAt(0);
        }
        _lines.add(message);
      }
      original(message, wrapWidth: wrapWidth);
    };
  }

  /// Returns a copy of the buffered log lines.
  List<String> dump() => List<String>.from(_lines);
}

