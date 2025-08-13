import 'package:flutter/material.dart';

class MarketplaceFilters {
  MarketplaceFilters({this.category, this.minPrice, this.maxPrice, this.query});

  String? category;
  double? minPrice;
  double? maxPrice;
  String? query;
}

class MarketplaceFiltersSheet extends StatefulWidget {
  const MarketplaceFiltersSheet({
    super.key,
    required this.initial,
    required this.onApply,
  });

  final MarketplaceFilters initial;
  final void Function(MarketplaceFilters) onApply;

  @override
  State<MarketplaceFiltersSheet> createState() => _MarketplaceFiltersSheetState();
}

class _MarketplaceFiltersSheetState extends State<MarketplaceFiltersSheet> {
  late final TextEditingController _category;
  late final TextEditingController _min;
  late final TextEditingController _max;
  late final TextEditingController _query;

  @override
  void initState() {
    super.initState();
    _category = TextEditingController(text: widget.initial.category);
    _min = TextEditingController(
        text: widget.initial.minPrice?.toStringAsFixed(2) ?? '');
    _max = TextEditingController(
        text: widget.initial.maxPrice?.toStringAsFixed(2) ?? '');
    _query = TextEditingController(text: widget.initial.query);
  }

  @override
  void dispose() {
    _category.dispose();
    _min.dispose();
    _max.dispose();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _query,
            decoration: const InputDecoration(labelText: 'Search'),
          ),
          TextField(
            controller: _category,
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          TextField(
            controller: _min,
            decoration: const InputDecoration(labelText: 'Min price'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _max,
            decoration: const InputDecoration(labelText: 'Max price'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final filters = MarketplaceFilters(
                category: _category.text.isEmpty ? null : _category.text,
                minPrice: double.tryParse(_min.text),
                maxPrice: double.tryParse(_max.text),
                query: _query.text.isEmpty ? null : _query.text,
              );
              widget.onApply(filters);
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
