import 'package:flutter/material.dart';
import '../tokens/app_decorations.dart';
import '../tokens/app_dimensions.dart';
import 'package:likha/core/theme/app_colors.dart';

/// A smaller reusable card shell with Pattern A-Small design.
///
/// Provides a 2-layer container decoration with smaller radius and bottom inset.
/// Used for teacher list items (assessments, assignments, submissions).
class BaseCardSm extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final Color outerColor;

  const BaseCardSm({
    super.key,
    required this.child,
    this.onTap,
    this.margin = const EdgeInsets.only(
      bottom: AppDimensions.kCardSmListSpacing,
    ),
    this.padding = const EdgeInsets.all(AppDimensions.kCardPadSm),
    this.outerColor = AppColors.borderLight,
  });

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      decoration: AppDecorations.cardShellSmInner(),
      margin: const EdgeInsets.fromLTRB(
        1,
        1,
        1,
        AppDimensions.kCardSmShellBottomInset,
      ),
      padding: padding,
      child: child,
    );

    final outer = Container(
      decoration: BoxDecoration(
        color: outerColor,
        borderRadius: BorderRadius.circular(AppDimensions.kCardSmOuterRadius),
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
