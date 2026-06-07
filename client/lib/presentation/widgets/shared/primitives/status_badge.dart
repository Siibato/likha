import 'package:flutter/material.dart';
import '../tokens/app_decorations.dart';
import '../tokens/app_text_styles.dart';
import 'package:likha/core/theme/app_colors.dart';

/// A bordered or filled pill badge used for status labels.
///
/// Supports two base variants:
/// - [BadgeVariant.outlined]: Border with light background (for semantic/dynamic colors)
/// - [BadgeVariant.filled]: Solid colored background at 15% opacity (for semantic/dynamic colors)
///
/// Named factories for design-system palette variants (no color param needed):
/// - [StatusBadge.base]: Light gray border, tertiary bg
/// - [StatusBadge.dark]: Charcoal bg, white text
/// - [StatusBadge.accent]: Amber bg, white text
/// - [StatusBadge.outline]: Dark charcoal border, white bg
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final BadgeVariant variant;
  final Color? _textColorOverride;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.variant = BadgeVariant.outlined,
  }) : _textColorOverride = null;

  const StatusBadge._internal({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    required this.variant,
    Color? textColorOverride,
  }) : _textColorOverride = textColorOverride;

  /// Light gray border, backgroundTertiary bg — neutral default
  factory StatusBadge.base({
    Key? key,
    required String label,
    IconData? icon,
  }) {
    return StatusBadge._internal(
      key: key,
      label: label,
      color: AppColors.foregroundSecondary,
      icon: icon,
      variant: BadgeVariant.outlined,
    );
  }

  /// Charcoal solid bg, white text — strong/prominent
  factory StatusBadge.dark({
    Key? key,
    required String label,
    IconData? icon,
  }) {
    return StatusBadge._internal(
      key: key,
      label: label,
      color: AppColors.accentCharcoal,
      icon: icon,
      variant: BadgeVariant.filled,
      textColorOverride: Colors.white,
    );
  }

  /// Amber solid bg, white text — highlight/CTA
  factory StatusBadge.accent({
    Key? key,
    required String label,
    IconData? icon,
  }) {
    return StatusBadge._internal(
      key: key,
      label: label,
      color: AppColors.accentAmber,
      icon: icon,
      variant: BadgeVariant.filled,
      textColorOverride: Colors.white,
    );
  }

  /// White bg, dark charcoal border — structured emphasis
  factory StatusBadge.outline({
    Key? key,
    required String label,
    IconData? icon,
  }) {
    return StatusBadge._internal(
      key: key,
      label: label,
      color: AppColors.borderPrimary,
      icon: icon,
      variant: BadgeVariant.outlined,
      textColorOverride: AppColors.foregroundDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = _textColorOverride ?? color;

    BoxDecoration decoration;
    if (variant == BadgeVariant.outlined) {
      decoration = _textColorOverride == AppColors.foregroundDark
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderPrimary, width: 1),
            )
          : AppDecorations.badgeOutlined(borderColor: color.withValues(alpha: 0.4));
    } else {
      decoration = AppDecorations.badgeFilled(color: color);
    }

    // dark/accent filled badges need fully opaque bg
    if (variant == BadgeVariant.filled && _textColorOverride != null) {
      decoration = BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      );
    }

    return Container(
      decoration: decoration,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: effectiveTextColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTextStyles.badgeLabelMd.copyWith(
              color: effectiveTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

enum BadgeVariant {
  outlined,
  filled,
}
