// lib/widgets/chat/chat_composer.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

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
  final ImagePicker _picker = ImagePicker();

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;
    widget.onSend(text, List.from(_attachments));
    _controller.clear();
    setState(() {
      _attachments.clear();
    });
  }

  Future<void> _pickAttachment() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _attachments.add(
          MediaItem(
            id: const Uuid().v4(),
            type: MediaType.image,
            url: picked.path,
          ),
        );
      });
    }
  }

  Future<void> _pickEmoji() async {
    const emojis = ['😀', '😂', '😍', '🤔', '👍', '🎉'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return GridView.count(
          crossAxisCount: 6,
          children: [
            for (final e in emojis)
              InkWell(
                onTap: () => Navigator.pop(context, e),
                child: Center(
                  child: Text(
                    e,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
          ],
        );
      },
    );
    if (selected != null) {
      final text = _controller.text;
      final selection = _controller.selection;
      final newText =
          text.replaceRange(selection.start, selection.end, selected);
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
          offset: selection.start + selected.length);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSend =
        _controller.text.trim().isNotEmpty || _attachments.isNotEmpty;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_attachments.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Wrap(
                  spacing: 8,
                  children: List.generate(_attachments.length, (index) {
                    final item = _attachments[index];
                    return Chip(
                      label: Text(item.type.name),
                      onDeleted: () {
                        setState(() {
                          _attachments.removeAt(index);
                        });
                      },
                    );
                  }),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _pickAttachment,
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
                  onPressed: _pickEmoji,
                  tooltip: 'Emoji',
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: canSend ? _handleSend : null,
                  tooltip: 'Send',
                ),
              ],
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
