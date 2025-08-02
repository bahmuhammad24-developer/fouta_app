import 'package:flutter/material.dart';
import 'package:fouta_app/theme/fouta_theme_diaspora.dart';

/// A simple segmented control used to toggle between multiple options. This
/// widget replaces chip rows or ad‑hoc toggles with a unified component.
class FoutaSegmentedControl extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const FoutaSegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  }) : assert(labels.length > 1, 'Segmented control requires at least two labels');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(FoutaTheme.buttonRadius),
        border: Border.all(color: FoutaTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final bool isSelected = selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? FoutaTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(FoutaTheme.buttonRadius),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[index],
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isSelected ? FoutaTheme.onPrimaryColor : FoutaTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}