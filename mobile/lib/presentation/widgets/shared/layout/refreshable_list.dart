import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// A [RefreshIndicator] + [ListView.builder] wrapper with consistent app styling.
///
/// Replaces the repeated pattern across 24 list pages:
/// ```dart
/// RefreshIndicator(
///   onRefresh: () => ref.read(provider.notifier).load(),
///   color: AppColors.accentCharcoal,
///   child: ListView.builder(
///     padding: const EdgeInsets.all(24),
///     itemCount: items.length,
///     itemBuilder: (context, index) => ...,
///   ),
/// )
/// ```
///
/// Usage:
/// ```dart
/// RefreshableList(
///   onRefresh: () => ref.read(provider.notifier).load(),
///   itemCount: items.length,
///   itemBuilder: (context, i) => ItemCard(item: items[i]),
/// )
/// ```
class RefreshableList extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsets padding;
  final Widget? header;
  final Widget? footer;

  const RefreshableList({
    super.key,
    required this.onRefresh,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(24),
    this.header,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.accentCharcoal,
      child: ListView.builder(
        padding: padding,
        itemCount: itemCount + (header != null ? 1 : 0) + (footer != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (header != null) {
            if (index == 0) return header!;
            index -= 1;
          }
          if (footer != null && index == itemCount) return footer!;
          return itemBuilder(context, index);
        },
      ),
    );
  }
}
