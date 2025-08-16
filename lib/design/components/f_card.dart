import 'package:flutter/material.dart';

import '../tokens.dart';

class FCard extends StatelessWidget {
  const FCard({
    super.key,
    required this.child,
    this.tier = FTier.t2,
    this.padding,
    this.clipBehavior,
  });

  final Widget child;
  final FTier tier;
  final EdgeInsetsGeometry? padding;
  final Clip? clipBehavior;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final double elevation;
    final EdgeInsetsGeometry pad;
    final double radius;
    switch (tier) {
      case FTier.t1:
        elevation = FElevation.level3;
        pad = padding ?? const EdgeInsets.all(FSpacing.s4);
        radius = FRadius.lg;
        break;
      case FTier.t2:
        elevation = FElevation.level2;
        pad = padding ?? const EdgeInsets.all(FSpacing.s3);
        radius = FRadius.md;
        break;
      case FTier.t3:
        elevation = FElevation.level0;
        pad = padding ?? const EdgeInsets.all(FSpacing.s2);
        radius = FRadius.sm;
        break;
    }

    return Card(
      clipBehavior: clipBehavior ?? Clip.none,
      color: FColors.surface(brightness),
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        padding: pad,
        child: child,
      ),
    );
  }
}
