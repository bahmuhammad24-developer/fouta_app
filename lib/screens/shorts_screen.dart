import 'package:flutter/material.dart';

class ShortsScreen extends StatelessWidget {
  const ShortsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shorts')),
      body: const Center(
        child: Text('Short-form videos coming soon.'),
      ),
    );
  }
}
