import 'package:flutter/material.dart';

/// Generic empty state widget.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? cta;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.cta,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center),
          if (cta != null) ...[
            const SizedBox(height: 16),
            cta!,
          ],
        ],
      ),
    );
  }
}

/// Generic error state widget.
class ErrorState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? cta;

  const ErrorState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.cta,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(icon: icon, title: title, message: message, cta: cta);
  }
}
