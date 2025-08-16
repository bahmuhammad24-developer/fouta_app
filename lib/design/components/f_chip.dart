import 'package:flutter/material.dart';

import '../tokens.dart';

class FChip extends StatelessWidget {
  const FChip({
    super.key,
    required this.label,
    this.tier = FTier.t3,
    this.selected = false,
    this.onSelected,
  });

  final String label;
  final FTier tier;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final brand = FColors.brand(brightness);
    final surface = FColors.surface(brightness);
    final surfaceAlt = FColors.surfaceAlt(brightness);
    final textPrimary = FColors.textPrimary(brightness);

    switch (tier) {
      case FTier.t1:
        return FilterChip(
          label: Text(label, style: FTypography.label.copyWith(color: surface)),
          selected: selected,
          onSelected: onSelected,
          backgroundColor: brand,
          selectedColor: brand,
        );
      case FTier.t2:
        return FilterChip(
          label: Text(label, style: FTypography.label.copyWith(color: brand)),
          selected: selected,
          onSelected: onSelected,
          backgroundColor: surface,
          selectedColor: brand.withOpacity(0.1),
          side: BorderSide(color: brand),
        );
      case FTier.t3:
        return FilterChip(
          label: Text(
            label,
            style: FTypography.label.copyWith(
              color: selected ? surface : textPrimary,
            ),
          ),
          selected: selected,
          onSelected: onSelected,
          backgroundColor: selected ? brand : surfaceAlt,
          selectedColor: brand,
        );
    }
  }
}
