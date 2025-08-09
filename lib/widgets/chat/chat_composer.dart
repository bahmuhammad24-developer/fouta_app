// lib/widgets/chat/chat_composer.dart

import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../models/media_item.dart';

class ChatComposer extends StatefulWidget {
  final void Function(String text, List<MediaItem> attachments) onSend;

  const ChatComposer({super.key, required this.onSend});

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final TextEditingController _controller = TextEditingController();
  final List<MediaItem> _attachments = [];

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;
    widget.onSend(text, List.from(_attachments));
    _controller.clear();
    setState(() {
      _attachments.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _controller.text.trim().isNotEmpty || _attachments.isNotEmpty;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: () {
                // TODO: implement attachment picker
              },
              tooltip: 'Attach',
            ),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Message',
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined),
              onPressed: () {
                // TODO: implement emoji picker
              },
              tooltip: 'Emoji',
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: canSend ? _handleSend : null,
              tooltip: 'Send',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
