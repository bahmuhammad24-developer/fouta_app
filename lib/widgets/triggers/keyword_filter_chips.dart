// lib/widgets/triggers/keyword_filter_chips.dart
import 'package:flutter/material.dart';

class KeywordFilterChips extends StatelessWidget {
  final List<String> tags;
  final String? selectedTag;
  final ValueChanged<String?> onSelected;
  final EdgeInsetsGeometry padding;

  const KeywordFilterChips({
    super.key,
    required this.tags,
    required this.selectedTag,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('All'),
              selected: selectedTag == null,
              onSelected: (_) => onSelected(null),
            ),
            const SizedBox(width: 8),
            ...tags.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('#$t'),
                    selected: selectedTag == t,
                    onSelected: (_) => onSelected(t),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
