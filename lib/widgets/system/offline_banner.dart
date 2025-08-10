import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cs.error.withOpacity(0.90),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'No internet connection',
            style: TextStyle(color: cs.onError, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
