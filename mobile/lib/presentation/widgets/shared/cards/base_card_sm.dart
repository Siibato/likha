import 'package:flutter/material.dart';
import '../tokens/app_decorations.dart';
import '../tokens/app_dimensions.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'base_card.dart';

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
  final BaseCardVariant variant;
  final bool enabled;
  final bool showShadow;

  const BaseCardSm({
    super.key,
    required this.child,
    this.onTap,
    this.margin = const EdgeInsets.only(
      bottom: AppDimensions.kCardSmListSpacing,
    ),
    this.padding = const EdgeInsets.all(AppDimensions.kCardPadSm),
    this.outerColor = AppColors.accentCharcoal,
    this.variant = BaseCardVariant.outline,
    this.enabled = true,
    this.showShadow = false,
  });

  /// Creates an accent small card with primary color styling
  factory BaseCardSm.accent({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets? margin,
    EdgeInsets? padding,
  }) {
    return BaseCardSm(
      onTap: onTap,
      margin: margin ?? const EdgeInsets.only(bottom: AppDimensions.kCardSmListSpacing),
      padding: padding ?? const EdgeInsets.all(AppDimensions.kCardPadSm),
      variant: BaseCardVariant.accent,
      child: child,
    );
  }

  /// Creates a success small card with green styling
  factory BaseCardSm.success({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets? margin,
    EdgeInsets? padding,
  }) {
    return BaseCardSm(
      onTap: onTap,
      margin: margin ?? const EdgeInsets.only(bottom: AppDimensions.kCardSmListSpacing),
      padding: padding ?? const EdgeInsets.all(AppDimensions.kCardPadSm),
      variant: BaseCardVariant.success,
      child: child,
    );
  }

  /// Creates a warning small card with amber styling
  factory BaseCardSm.warning({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets? margin,
    EdgeInsets? padding,
  }) {
    return BaseCardSm(
      onTap: onTap,
      margin: margin ?? const EdgeInsets.only(bottom: AppDimensions.kCardSmListSpacing),
      padding: padding ?? const EdgeInsets.all(AppDimensions.kCardPadSm),
      variant: BaseCardVariant.warning,
      child: child,
    );
  }

  /// Creates an error small card with red styling
  factory BaseCardSm.error({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets? margin,
    EdgeInsets? padding,
  }) {
    return BaseCardSm(
      onTap: onTap,
      margin: margin ?? const EdgeInsets.only(bottom: AppDimensions.kCardSmListSpacing),
      padding: padding ?? const EdgeInsets.all(AppDimensions.kCardPadSm),
      variant: BaseCardVariant.error,
      child: child,
    );
  }

  /// Creates a disabled small card
  factory BaseCardSm.disabled({
    required Widget child,
    EdgeInsets? margin,
    EdgeInsets? padding,
  }) {
    return BaseCardSm(
      margin: margin ?? const EdgeInsets.only(bottom: AppDimensions.kCardSmListSpacing),
      padding: padding ?? const EdgeInsets.all(AppDimensions.kCardPadSm),
      enabled: false,
      child: child,
    );
  }

  Color _getVariantColor() {
    switch (variant) {
      case BaseCardVariant.accent:
        return AppColors.accentAmber;
      case BaseCardVariant.success:
        return AppColors.semanticSuccessAlt;
      case BaseCardVariant.warning:
        return AppColors.accentAmber;
      case BaseCardVariant.error:
        return AppColors.semanticErrorDark;
      case BaseCardVariant.base:
        return AppColors.borderLight;
      case BaseCardVariant.dark:
        return AppColors.accentCharcoalDark;
      case BaseCardVariant.accentFill:
        return AppColors.accentAmberBorder;
      case BaseCardVariant.outline:
        return AppColors.borderPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOuterColor = enabled ? _getVariantColor() : AppColors.borderLight;

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
        color: effectiveOuterColor,
        borderRadius: BorderRadius.circular(AppDimensions.kCardSmOuterRadius),
        boxShadow: showShadow ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      margin: margin,
      child: inner,
    );

    if (onTap != null && enabled) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.kCardSmOuterRadius),
          child: outer,
        ),
      );
    }

    return outer;
  }
}
