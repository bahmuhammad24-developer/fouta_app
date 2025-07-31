import 'package:flutter/material.dart';
import 'package:fouta_app/theme/fouta_theme.dart';

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
        borderRadius: BorderRadius.circular(FoutaTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(FoutaTheme.cardRadius),
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}