import 'package:flutter/material.dart';

import 'motion.dart';

/// Reusable page transitions for the app.
class FoutaTransitions {
  /// Slides [child] in from the right.
  static PageRouteBuilder<T> pushFromRight<T>(Widget child) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => child,
      transitionDuration: FoutaMotion.duration,
      transitionsBuilder: (_, animation, __, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: FoutaMotion.curve));
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  /// Fades [child] in.
  static PageRouteBuilder<T> fadeIn<T>(Widget child) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => child,
      transitionDuration: FoutaMotion.duration,
      transitionsBuilder: (_, animation, __, child) {
        final fade = CurvedAnimation(parent: animation, curve: FoutaMotion.curve);
        return FadeTransition(opacity: fade, child: child);
      },
    );
  }

  /// Scales [child] in.
  static PageRouteBuilder<T> scaleIn<T>(Widget child) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => child,
      transitionDuration: FoutaMotion.duration,
      transitionsBuilder: (_, animation, __, child) {
        final scale = Tween<double>(begin: 0.9, end: 1)
            .animate(CurvedAnimation(parent: animation, curve: FoutaMotion.curve));
        return ScaleTransition(scale: scale, child: child);
      },
    );
  }
}
