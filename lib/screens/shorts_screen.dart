import 'package:flutter/material.dart';
import 'package:fouta_app/features/shorts/shorts_service.dart';
import 'package:fouta_app/utils/json_safety.dart';

class ShortsScreen extends StatelessWidget {
  const ShortsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ShortsService();
    return Scaffold(
      appBar: AppBar(title: const Text('Shorts')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.fetchShorts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final shorts = snapshot.data ?? [];
          if (shorts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_outline, size: 48),
                  SizedBox(height: 16),
                  Text('No shorts yet'),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: shorts.length,
            itemBuilder: (context, index) {
              final data = shorts[index];
              final url = data['url']?.toString() ?? '';
              final likes = asStringList(data['likes']).length;
              return ListTile(
                leading: const Icon(Icons.play_arrow),
                title: Text(url),
                subtitle: Text('$likes likes'),
              );
            },
          );
        },
      ),
    );
  }
}
