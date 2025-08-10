import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A tiny dev-only gesture to dismiss any stacked routes or overlays.
///
/// Triple tap the top-right corner (within a 64x64 hotspot) to pop all
/// routes in the current [Navigator]. This is only enabled in debug or
/// profile builds; in release mode it simply returns the [child] unchanged.
class PanicDismiss extends StatelessWidget {
  const PanicDismiss({super.key, required this.child});

  /// The widget subtree to wrap with the panic-dismiss gesture.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // No-op in release mode to avoid affecting production behavior.
    if (kReleaseMode) return child;

    int taps = 0;
    DateTime last = DateTime.now();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (details) {
        final size = MediaQuery.of(context).size;
        final inHotspot =
            details.globalPosition.dx > size.width - 64 && details.globalPosition.dy < 64;
        if (!inHotspot) return;

        final now = DateTime.now();
        // Reset the tap counter if too much time has elapsed between taps.
        if (now.difference(last) > const Duration(milliseconds: 600)) {
          taps = 0;
        }
        taps++;
        last = now;

        if (taps >= 3) {
          taps = 0;
          // Pop any transient routes or overlays that can be popped.
          final nav = Navigator.of(context);
          int popped = 0;
          while (nav.canPop()) {
            nav.pop();
            popped++;
          }
          debugPrint('PanicDismiss: popped $popped route(s).');
        }
      },
      child: child,
    );
  }
}

