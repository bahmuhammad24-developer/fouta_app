import 'package:flutter/material.dart';

/// Scaffold that wraps a [CustomScrollView] with pull-to-refresh and
/// empty/error state handling.
class RefreshScaffold extends StatelessWidget {
  final RefreshCallback onRefresh;
  final List<Widget> slivers;
  final Widget? empty;
  final Widget? error;

  const RefreshScaffold({
    super.key,
    required this.onRefresh,
    required this.slivers,
    this.empty,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> content = slivers;
    if (error != null) {
      content = [SliverFillRemaining(hasScrollBody: false, child: error!)];
    } else if (empty != null && slivers.isEmpty) {
      content = [SliverToBoxAdapter(child: empty!)];
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(slivers: content),
    );
  }
}
