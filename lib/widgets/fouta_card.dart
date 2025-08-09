import 'package:flutter/material.dart';
// Removed dependency on FoutaTheme constants. Card styling now uses
// the current theme's colours and a fixed radius value to ensure
// compatibility with both the Minimalist nature and Diaspora themes.
// Removed dependency on FoutaTheme. Use a fixed radius value so this
// widget can adapt to any theme.

/// A simple container with consistent margin, padding, corner radius and
/// elevation used to display content throughout the Fouta app.  This widget
/// ensures that cards across posts, messages, events and other screens
/// share the same look and feel.
class FoutaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const FoutaCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}