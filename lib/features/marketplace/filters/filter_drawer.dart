import 'package:flutter/material.dart';

import '../../../widgets/fouta_card.dart';
import 'marketplace_filters.dart';

/// Drawer for adjusting marketplace filters. Updates persist per-user and
/// emit changes live via [MarketplaceFiltersRepository].
class MarketplaceFilterDrawer extends StatefulWidget {
  const MarketplaceFilterDrawer({
    super.key,
    required this.repository,
    required this.uid,
  });

  final MarketplaceFiltersRepository repository;
  final String uid;

  @override
  State<MarketplaceFilterDrawer> createState() => _MarketplaceFilterDrawerState();
}

class _MarketplaceFilterDrawerState extends State<MarketplaceFilterDrawer> {
  MarketplaceFilters _filters = const MarketplaceFilters();

  @override
  void initState() {
    super.initState();
    widget.repository.fetch(widget.uid).then((f) {
      if (mounted) setState(() => _filters = f);
    });
  }

  void _save(MarketplaceFilters f) {
    setState(() => _filters = f);
    widget.repository.save(widget.uid, f);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FoutaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Price Range'),
                  RangeSlider(
                    values: RangeValues(
                      _filters.minPrice ?? 0,
                      _filters.maxPrice ?? 1000,
                    ),
                    min: 0,
                    max: 1000,
                    labels: RangeLabels(
                      (_filters.minPrice ?? 0).toStringAsFixed(0),
                      (_filters.maxPrice ?? 1000).toStringAsFixed(0),
                    ),
                    onChanged: (values) {
                      _save(_filters.copyWith(
                        minPrice: values.start,
                        maxPrice: values.end == 1000 ? null : values.end,
                      ));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FoutaCard(
              child: Wrap(
                spacing: 8,
                children: [
                  const Text('Category'),
                  ..._categories.map((c) => FilterChip(
                        label: Text(c),
                        selected: _filters.category == c,
                        onSelected: (_) => _save(
                          _filters.copyWith(category: _filters.category == c ? null : c),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FoutaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Location Radius (km)'),
                  Slider(
                    value: _filters.radiusKm ?? 10,
                    min: 1,
                    max: 100,
                    label: (_filters.radiusKm ?? 10).toStringAsFixed(0),
                    onChanged: (v) => _save(
                      _filters.copyWith(radiusKm: v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FoutaCard(
              child: Wrap(
                spacing: 8,
                children: [
                  const Text('Sort'),
                  ...MarketplaceSort.values.map(
                    (s) => ChoiceChip(
                      label: Text(_sortLabel(s)),
                      selected: _filters.sort == s,
                      onSelected: (_) => _save(_filters.copyWith(sort: s)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _categories = ['Electronics', 'Home', 'Other'];

String _sortLabel(MarketplaceSort s) {
  switch (s) {
    case MarketplaceSort.priceAsc:
      return 'Price ↑';
    case MarketplaceSort.priceDesc:
      return 'Price ↓';
    case MarketplaceSort.newest:
    default:
      return 'Newest';
  }
}
