import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../utils/bug_reporter.dart';

class ReportBugScreen extends StatefulWidget {
  const ReportBugScreen({super.key});

  @override
  State<ReportBugScreen> createState() => _ReportBugScreenState();
}

class _ReportBugScreenState extends State<ReportBugScreen> {
  Uint8List? _screenshot;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bytes = await BugReporter.capturePng(context);
      if (!mounted) return;
      setState(() => _screenshot = bytes);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final bytes = await BugReporter.capturePng(context);
    setState(() => _screenshot = bytes);
  }

  Future<void> _submit() async {
    final desc = _controller.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await BugReporter.submit(
        context,
        description: desc,
        screenshot: _screenshot,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bug report sent')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Report a Bug')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_screenshot != null)
            Card(
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Image.memory(_screenshot!, height: 200, fit: BoxFit.cover),
                  TextButton(onPressed: _capture, child: const Text('Retake')),
                ],
              ),
            ),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _sending ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: _sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send'),
          ),
        ],
      ),
    );
  }
}

