import 'package:flutter/material.dart';

/// Duration tokens used for animations.
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 700);
}

/// Curve tokens for consistent motion.
class AppCurves {
  AppCurves._();

  static const Curve easeOutQuad = Cubic(0.25, 0.46, 0.45, 0.94);
  static const Curve easeInOutCubic = Curves.easeInOutCubic;
}

/// Adds a small scale animation when the child is tapped.
Widget animateOnTap({
  required Widget child,
  required VoidCallback onTap,
}) {
  return _TapAnimator(child: child, onTap: onTap);
}

/// Shows or hides a widget with a fade transition.
Widget animatedVisibility({
  required bool visible,
  required Widget child,
  Duration duration = AppDurations.normal,
}) {
  return AnimatedSwitcher(
    duration: duration,
    switchInCurve: AppCurves.easeOutQuad,
    switchOutCurve: AppCurves.easeOutQuad,
    child: visible ? child : const SizedBox.shrink(),
  );
}

class _TapAnimator extends StatefulWidget {
  const _TapAnimator({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_TapAnimator> createState() => _TapAnimatorState();
}

class _TapAnimatorState extends State<_TapAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.fast,
    lowerBound: 0.95,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.reverse();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.forward();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _controller,
        child: widget.child,
      ),
    );
  }
}

