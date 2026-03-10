import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'app_dimensions.dart';

/// Design system decoration constants for Likha LMS.
///
/// All [BoxDecoration] values used for cards, inputs, and other styled containers
/// are defined here as static factory methods.
abstract final class AppDecorations {
  // ============ CARD SHELLS - PATTERN A ============
  /// Outer container decoration for Pattern A cards (raised bottom border effect)
  static BoxDecoration cardShellOuter() {
    return BoxDecoration(
      color: AppColors.borderLight,
      borderRadius: BorderRadius.circular(AppDimensions.kCardOuterRadius),
    );
  }

  /// Inner container decoration for Pattern A cards
  static BoxDecoration cardShellInner() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppDimensions.kCardInnerRadius),
    );
  }

  // ============ CARD SHELLS - PATTERN A-SMALL ============
  /// Outer container decoration for Pattern A-Small cards (teacher list items)
  static BoxDecoration cardShellSmOuter() {
    return BoxDecoration(
      color: AppColors.borderLight,
      borderRadius: BorderRadius.circular(AppDimensions.kCardSmOuterRadius),
    );
  }

  /// Inner container decoration for Pattern A-Small cards
  static BoxDecoration cardShellSmInner() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppDimensions.kCardSmInnerRadius),
    );
  }

  // ============ CARD SHELLS - PATTERN B (FLAT) ============
  /// Flat bordered panel decoration (detail-page panels)
  static BoxDecoration infoPanel() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppDimensions.kPanelRadius),
      border: Border.all(
        color: AppColors.borderLight,
        width: 1,
      ),
    );
  }

  // ============ ICON SLOTS ============
  /// Rounded square background for icons in cards
  static BoxDecoration iconSlotBg() {
    return BoxDecoration(
      color: AppColors.backgroundTertiary,
      borderRadius: BorderRadius.circular(AppDimensions.kIconSlotRadius),
    );
  }

  // ============ BADGES ============
  /// Outlined badge decoration (border + background)
  static BoxDecoration badgeOutlined({Color? borderColor}) {
    return BoxDecoration(
      color: AppColors.backgroundTertiary,
      borderRadius: BorderRadius.circular(AppDimensions.kBadgeRadiusLg),
      border: Border.all(
        color: borderColor ?? AppColors.borderLight,
        width: 1,
      ),
    );
  }

  /// Filled badge decoration (solid background)
  static BoxDecoration badgeFilled({required Color color}) {
    return BoxDecoration(
      color: color.withAlpha((0.15 * 255).toInt()),
      borderRadius: BorderRadius.circular(AppDimensions.kBadgeRadiusSm),
    );
  }

  // ============ FORM INPUTS ============
  /// Outer wrapper for text inputs (2-layer shell)
  static BoxDecoration inputShellOuter() {
    return BoxDecoration(
      color: AppColors.borderLight,
      borderRadius: BorderRadius.circular(12),
    );
  }

  /// Inner wrapper for text inputs (2-layer shell)
  static BoxDecoration inputShellInner() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
    );
  }
}
