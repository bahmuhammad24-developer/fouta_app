import 'package:flutter/material.dart';
import 'package:fouta_app/theme/fouta_theme.dart';

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
    final Widget button = primary
        ? ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FoutaTheme.accentColor,
              foregroundColor: FoutaTheme.onSecondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FoutaTheme.buttonRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: onPressed,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
            ),
          )
        : OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: FoutaTheme.primaryColor,
              side: const BorderSide(color: FoutaTheme.primaryColor, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FoutaTheme.buttonRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: onPressed,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: FoutaTheme.primaryColor,
                  ),
            ),
          );

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}