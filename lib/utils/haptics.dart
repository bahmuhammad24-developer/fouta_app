import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class Haptics {
  const Haptics._();

  static Future<void> light() async {
    if (kIsWeb) return;
    await HapticFeedback.lightImpact();
  }

  static Future<void> medium() async {
    if (kIsWeb) return;
    await HapticFeedback.mediumImpact();
  }

  static Future<void> success() async {
    if (kIsWeb) return;
    await HapticFeedback.heavyImpact();
  }
}
