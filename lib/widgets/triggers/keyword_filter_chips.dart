import 'package:flutter/material.dart';

class KeywordFilterChips extends StatelessWidget {
  const KeywordFilterChips({super.key, required this.keywords, required this.onSelected});

  final List<String> keywords;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (keywords.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: keywords
            .map((k) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ActionChip(
                    label: Text(k),
                    onPressed: () => onSelected(k),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
