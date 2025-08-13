import 'package:flutter/material.dart';

/// Generic skeleton loader widgets.
class Skeleton extends StatelessWidget {
  const Skeleton._({
    required this.width,
    required this.height,
    required this.borderRadius,
    this.shimmer = true,
  });

  factory Skeleton.line({
    double width = double.infinity,
    double height = 16,
    bool shimmer = true,
  }) {
    return Skeleton._(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(4),
      shimmer: shimmer,
    );
  }

  factory Skeleton.rect({
    double width = double.infinity,
    double height = 16,
    double radius = 8,
    bool shimmer = true,
  }) {
    return Skeleton._(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(radius),
      shimmer: shimmer,
    );
  }

  factory Skeleton.avatar({
    double size = 40,
    bool shimmer = true,
  }) {
    return Skeleton._(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
      shimmer: shimmer,
    );
  }

  final double width;
  final double height;
  final BorderRadius borderRadius;
  final bool shimmer;

  @override
  Widget build(BuildContext context) {
    final base = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: borderRadius,
      ),
    );

    if (!shimmer) return base;

    return Stack(
      children: [
        base,
        Positioned.fill(
          child: AnimatedGradient(borderRadius: borderRadius),
        ),
      ],
    );
  }
}

/// Simple shimmering gradient used by [Skeleton].
class AnimatedGradient extends StatefulWidget {
  const AnimatedGradient({super.key, required this.borderRadius});

  final BorderRadius borderRadius;

  @override
  State<AnimatedGradient> createState() => _AnimatedGradientState();
}

class _AnimatedGradientState extends State<AnimatedGradient>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FractionallySizedBox(
            widthFactor: 1,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1 - 2 * _controller.value, 0),
                  end: Alignment(1 + 2 * _controller.value, 0),
                  colors: [
                    Colors.grey.shade300,
                    Colors.grey.shade100,
                    Colors.grey.shade300,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

