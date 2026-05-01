import 'package:flutter/material.dart';
import '../tokens/app_decorations.dart';
import '../tokens/app_dimensions.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Card variants for different styling needs
enum BaseCardVariant {
  standard,
  subtle,
  accent,
  success,
  warning,
  error,
}

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
  final BaseCardVariant variant;
  final bool enabled;
  final double? borderRadius;
  final bool showShadow;

  const BaseCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin = const EdgeInsets.only(
      bottom: AppDimensions.kCardListSpacing,
    ),
    this.padding = const EdgeInsets.all(AppDimensions.kCardPadMd),
    this.outerColor = AppColors.accentCharcoal,
    this.variant = BaseCardVariant.standard,
    this.enabled = true,
    this.borderRadius,
    this.showShadow = false,
  });

  /// Creates a subtle card with reduced visual weight
  factory BaseCard.subtle({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets? margin,
    EdgeInsets? padding,
  }) {
    return BaseCard(
      child: child,
      onTap: onTap,
      margin: margin ?? const EdgeInsets.only(bottom: AppDimensions.kCardListSpacing),
      padding: padding ?? const EdgeInsets.all(AppDimensions.kCardPadMd),
      variant: BaseCardVariant.subtle,
    );
  }

  /// Creates an accent card with primary color styling
  factory BaseCard.accent({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets? margin,
    EdgeInsets? padding,
  }) {
    return BaseCard(
      child: child,
      onTap: onTap,
      margin: margin ?? const EdgeInsets.only(bottom: AppDimensions.kCardListSpacing),
      padding: padding ?? const EdgeInsets.all(AppDimensions.kCardPadMd),
      variant: BaseCardVariant.accent,
    );
  }

  /// Creates a success card with green styling
  factory BaseCard.success({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets? margin,
    EdgeInsets? padding,
  }) {
    return BaseCard(
      child: child,
      onTap: onTap,
      margin: margin ?? const EdgeInsets.only(bottom: AppDimensions.kCardListSpacing),
      padding: padding ?? const EdgeInsets.all(AppDimensions.kCardPadMd),
      variant: BaseCardVariant.success,
    );
  }

  /// Creates a warning card with amber styling
  factory BaseCard.warning({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets? margin,
    EdgeInsets? padding,
  }) {
    return BaseCard(
      child: child,
      onTap: onTap,
      margin: margin ?? const EdgeInsets.only(bottom: AppDimensions.kCardListSpacing),
      padding: padding ?? const EdgeInsets.all(AppDimensions.kCardPadMd),
      variant: BaseCardVariant.warning,
    );
  }

  /// Creates an error card with red styling
  factory BaseCard.error({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets? margin,
    EdgeInsets? padding,
  }) {
    return BaseCard(
      child: child,
      onTap: onTap,
      margin: margin ?? const EdgeInsets.only(bottom: AppDimensions.kCardListSpacing),
      padding: padding ?? const EdgeInsets.all(AppDimensions.kCardPadMd),
      variant: BaseCardVariant.error,
    );
  }

  /// Creates a disabled card
  factory BaseCard.disabled({
    required Widget child,
    EdgeInsets? margin,
    EdgeInsets? padding,
  }) {
    return BaseCard(
      child: child,
      margin: margin ?? const EdgeInsets.only(bottom: AppDimensions.kCardListSpacing),
      padding: padding ?? const EdgeInsets.all(AppDimensions.kCardPadMd),
      enabled: false,
    );
  }

  Color _getVariantColor() {
    switch (variant) {
      case BaseCardVariant.standard:
        return AppColors.accentCharcoal;
      case BaseCardVariant.subtle:
        return AppColors.borderLight;
      case BaseCardVariant.accent:
        return AppColors.accentAmber;
      case BaseCardVariant.success:
        return AppColors.semanticSuccessAlt;
      case BaseCardVariant.warning:
        return AppColors.accentAmber;
      case BaseCardVariant.error:
        return AppColors.semanticErrorDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOuterColor = enabled ? _getVariantColor() : AppColors.borderLight;
    final effectiveBorderRadius = borderRadius ?? AppDimensions.kCardOuterRadius;

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
        color: effectiveOuterColor,
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        boxShadow: showShadow ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
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
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
          child: outer,
        ),
      );
    }

    return outer;
  }
}
