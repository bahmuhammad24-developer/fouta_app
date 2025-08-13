import 'package:flutter/material.dart';

import '../features/link_preview/link_preview_card.dart';
import '../features/link_preview/link_preview_service.dart';

/// Simple screen to manually test link previews.
class LinkPreviewDemoScreen extends StatefulWidget {
  const LinkPreviewDemoScreen({super.key});

  @override
  State<LinkPreviewDemoScreen> createState() => _LinkPreviewDemoScreenState();
}

class _LinkPreviewDemoScreenState extends State<LinkPreviewDemoScreen> {
  final _controller = TextEditingController();
  final _service = const LinkPreviewService();
  LinkPreviewData? _data;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _preview() async {
    final data = await _service.fetch(_controller.text);
    setState(() => _data = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Link Preview Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'URL'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _preview,
              child: const Text('Preview'),
            ),
            const SizedBox(height: 16),
            if (_data != null) LinkPreviewCard(data: _data!),
          ],
        ),
      ),
    );
  }
}

Map<String, WidgetBuilder> linkPreviewRoutes() =>
    {'/_dev/link-preview': (_) => const LinkPreviewDemoScreen()};

