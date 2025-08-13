import 'package:flutter/material.dart';

import '../utils/haptics.dart';

class AnimatedBookmarkButton extends StatefulWidget {
  const AnimatedBookmarkButton({
    super.key,
    required this.isSaved,
    required this.onChanged,
  });

  final bool isSaved;
  final ValueChanged<bool> onChanged;

  @override
  State<AnimatedBookmarkButton> createState() => _AnimatedBookmarkButtonState();
}

class _AnimatedBookmarkButtonState extends State<AnimatedBookmarkButton>
    with SingleTickerProviderStateMixin {
  late bool _saved;
  bool _pressed = false;
  late final AnimationController _checkmarkController;

  @override
  void initState() {
    super.initState();
    _saved = widget.isSaved;
    _checkmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedBookmarkButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSaved != widget.isSaved) {
      _saved = widget.isSaved;
    }
  }

  @override
  void dispose() {
    _checkmarkController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _saved = !_saved);
    if (_saved) {
      _checkmarkController.forward(from: 0);
      Haptics.success();
    } else {
      Haptics.medium();
    }
    widget.onChanged(_saved);
  }

  @override
  Widget build(BuildContext context) {
    final icon = _saved ? Icons.bookmark : Icons.bookmark_border;
    final label = _saved ? 'Remove bookmark' : 'Bookmark';

    final checkmark = FadeTransition(
      opacity: _checkmarkController.drive(CurveTween(curve: Curves.easeOut)),
      child: ScaleTransition(
        scale: _checkmarkController.drive(CurveTween(curve: Curves.easeOut)),
        child: const Icon(Icons.check, color: Colors.green),
      ),
    );

    return Semantics(
      button: true,
      label: label,
      toggled: _saved,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          _toggle();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon),
              if (_saved) checkmark,
            ],
          ),
        ),
      ),
    );
  }
}
