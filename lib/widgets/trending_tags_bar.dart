import 'package:flutter/material.dart';

class TrendingTagsBar extends StatelessWidget {
  const TrendingTagsBar({
    super.key,
    required this.tags,
    required this.onSelected,
    this.selectedTag,
  });

  final List<String> tags;
  final ValueChanged<String?> onSelected;
  final String? selectedTag;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: tags
            .map((t) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text('#$t'),
                    selected: selectedTag == t,
                    onSelected: (_) =>
                        onSelected(selectedTag == t ? null : t),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
