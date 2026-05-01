import 'package:flutter/material.dart';
import '../tokens/app_decorations.dart';
import '../tokens/app_dimensions.dart';
import 'package:likha/core/theme/app_colors.dart';

/// A reusable card shell with the Pattern A design (raised bottom border effect).
///
/// Provides a 2-layer container decoration and optional tap handling.
/// Used as a base for all list-item cards across the app.
class BaseCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final Color outerColor;

  const BaseCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin = const EdgeInsets.only(
      bottom: AppDimensions.kCardListSpacing,
    ),
    this.padding = const EdgeInsets.all(AppDimensions.kCardPadMd),
    this.outerColor = AppColors.accentCharcoal,
  });

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      decoration: AppDecorations.cardShellInner(),
      margin: const EdgeInsets.fromLTRB(
        1,
        1,
        1,
        AppDimensions.kCardShellBottomInset,
      ),
      padding: padding,
      child: child,
    );

    final outer = Container(
      decoration: BoxDecoration(
        color: outerColor,
        borderRadius: BorderRadius.circular(AppDimensions.kCardOuterRadius),
      ),
      margin: margin,
      child: inner,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: outer,
      );
    }

    return outer;
  }
}
