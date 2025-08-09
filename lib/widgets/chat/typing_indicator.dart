// lib/widgets/chat/typing_indicator.dart

import 'package:flutter/material.dart';

class TypingIndicator extends StatelessWidget {
  final String text;

  const TypingIndicator({super.key, this.text = 'Someone is typing...'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}
