import 'package:flutter/material.dart';
// Removed direct dependency on FoutaTheme constants. The button colours
// are now derived from the current theme's colour scheme. This allows
// the button to adapt automatically to both the Minimalist nature and
// Diaspora Connection themes.
// We no longer rely on FoutaTheme; instead, we use a fixed radius and
// theme-based colours to ensure the button adapts to any app theme.

/// A reusable button for Fouta that conforms to the Minimalist nature
/// design guidelines. It supports primary (filled) and secondary (outlined)
/// styles and ensures consistent padding, radius, and typography.
class FoutaButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final bool expanded;

  const FoutaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = true,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    // Use the theme's colour scheme instead of hard-coded palette values.
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // Use a fixed radius to avoid depending on FoutaTheme. This radius
    // reflects the guidelines from the design system (10dp).
    const double radius = 10.0;
    final Widget button = primary
        ? ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.secondary,
              foregroundColor: scheme.onSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: onPressed,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSecondary,
                  ),
            ),
          )
        : OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.primary,
              side: BorderSide(color: scheme.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: onPressed,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
            ),
          );

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}