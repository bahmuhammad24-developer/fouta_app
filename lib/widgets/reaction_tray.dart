import 'package:flutter/material.dart';

import '../utils/haptics.dart';

enum ReactionType { like, love, haha, wow, sad, angry }

typedef ReactionSelected = void Function(ReactionType type);

class ReactionTray extends StatefulWidget {
  const ReactionTray({
    super.key,
    required this.onReactionSelected,
  });

  final ReactionSelected onReactionSelected;

  @override
  State<ReactionTray> createState() => _ReactionTrayState();
}

class _ReactionTrayState extends State<ReactionTray> {
  bool _expanded = false;
  int? _activeIndex;
  static const _emojis = ['👍', '❤️', '😂', '😮', '😢', '😡'];

  void _select(int index) {
    widget.onReactionSelected(ReactionType.values[index]);
    Haptics.light();
    setState(() {
      _expanded = false;
      _activeIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => setState(() => _expanded = true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        width: _expanded ? 240 : 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: _expanded
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_emojis.length, (index) {
                  final emoji = _emojis[index];
                  final active = _activeIndex == index;
                  return MouseRegion(
                    onEnter: (_) => setState(() => _activeIndex = index),
                    onExit: (_) => setState(() => _activeIndex = null),
                    child: GestureDetector(
                      onTapDown: (_) => setState(() => _activeIndex = index),
                      onTapCancel: () => setState(() => _activeIndex = null),
                      onTapUp: (_) => _select(index),
                      child: AnimatedScale(
                        scale: active ? 1.4 : 1.0,
                        duration: const Duration(milliseconds: 100),
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  );
                }),
              )
            : const Center(child: Text('👍', style: TextStyle(fontSize: 24))),
      ),
    );
  }
}
