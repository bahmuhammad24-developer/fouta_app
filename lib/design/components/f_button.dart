import 'package:flutter/material.dart';

import '../tokens.dart';

class FButton extends StatelessWidget {
  const FButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tier = FTier.t1,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final FTier tier;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final brand = FColors.brand(brightness);
    final surface = FColors.surface(brightness);
    final padding = const EdgeInsets.symmetric(
      horizontal: FSpacing.s4,
      vertical: FSpacing.s3,
    );

    ButtonStyle style;
    switch (tier) {
      case FTier.t1:
        style = ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: surface,
          padding: padding,
        );
        break;
      case FTier.t2:
        style = OutlinedButton.styleFrom(
          foregroundColor: brand,
          padding: padding,
          side: BorderSide(color: brand),
        );
        break;
      case FTier.t3:
        style = TextButton.styleFrom(
          foregroundColor: brand,
          padding: padding,
        );
        break;
    }

    Widget button;
    switch (tier) {
      case FTier.t1:
        button = ElevatedButton(onPressed: onPressed, style: style, child: Text(label));
        break;
      case FTier.t2:
        button = OutlinedButton(onPressed: onPressed, style: style, child: Text(label));
        break;
      case FTier.t3:
        button = TextButton(onPressed: onPressed, style: style, child: Text(label));
        break;
    }

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
