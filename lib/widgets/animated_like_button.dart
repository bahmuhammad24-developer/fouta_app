import 'package:flutter/material.dart';

import '../utils/haptics.dart';

class AnimatedLikeButton extends StatefulWidget {
  const AnimatedLikeButton({
    super.key,
    required this.isLiked,
    required this.onChanged,
  });

  final bool isLiked;
  final ValueChanged<bool> onChanged;

  @override
  State<AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<AnimatedLikeButton>
    with SingleTickerProviderStateMixin {
  late bool _liked;
  bool _pressed = false;
  late final AnimationController _controller;
  late final Animation<double> _burst;

  @override
  void initState() {
    super.initState();
    _liked = widget.isLiked;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _burst = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant AnimatedLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked) {
      _liked = widget.isLiked;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _liked = !_liked);
    if (_liked) {
      _controller.forward(from: 0);
    }
    Haptics.light();
    widget.onChanged(_liked);
  }

  @override
  Widget build(BuildContext context) {
    final icon = _liked ? Icons.favorite : Icons.favorite_border;
    final color = _liked ? Colors.red : null;
    final label = _liked ? 'Unlike' : 'Like';

    return Semantics(
      button: true,
      label: label,
      toggled: _liked,
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
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.scale(
              scale: _liked ? _burst.value : 1.0,
              child: child,
            ),
            child: Icon(icon, color: color),
          ),
        ),
      ),
    );
  }
}
