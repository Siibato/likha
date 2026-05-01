import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Design system typography constants for Likha LMS.
///
/// All [TextStyle] values used across the app are defined here.
/// This ensures visual consistency and makes it easy to update the design system.
abstract final class AppTextStyles {
  // ============ CARD TITLES ============
  /// Large card title (column layouts)
  static const TextStyle cardTitleLg = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.foregroundDark,
    letterSpacing: -0.4,
  );

  /// Medium card title (row layouts, default)
  static const TextStyle cardTitleMd = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.foregroundDark,
    letterSpacing: -0.4,
  );

  /// Small card title (A-Small cards)
  static const TextStyle cardTitleSm = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.foregroundDark,
    letterSpacing: -0.3,
  );

  // ============ CARD SUBTITLES ============
  /// Medium subtitle (secondary text in cards)
  static const TextStyle cardSubtitleMd = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.foregroundTertiary,
  );

  /// Small subtitle
  static const TextStyle cardSubtitleSm = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.foregroundTertiary,
  );

  // ============ DIALOG ============
  /// Dialog title
  static const TextStyle dialogTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.foregroundDark,
    letterSpacing: -0.4,
  );

  /// Dialog subtitle
  static const TextStyle dialogSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.foregroundTertiary,
  );

  /// Dialog body text with increased line height
  static const TextStyle dialogBody = TextStyle(
    fontSize: 15,
    height: 1.4,
  );

  // ============ BADGES ============
  /// Medium badge label
  static const TextStyle badgeLabelMd = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  /// Small badge label
  static const TextStyle badgeLabelSm = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );

  // ============ FORM INPUTS ============
  /// Input label text
  static const TextStyle inputLabel = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.foregroundTertiary,
  );

  /// Input text content
  static const TextStyle inputText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.foregroundDark,
  );

  // ============ SECTION HEADERS ============
  /// Large section title (e.g., page headers)
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.foregroundPrimary,
    letterSpacing: -0.5,
  );

  // ============ DESKTOP PAGE HEADERS ============
  /// Desktop page scaffold title
  static const TextStyle desktopPageTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.foregroundDark,
    letterSpacing: -0.5,
  );

  /// Desktop page scaffold subtitle
  static const TextStyle desktopPageSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.foregroundSecondary,
  );

  // ============ MOBILE PAGE HEADERS ============
  /// Mobile page scaffold title (AppBar)
  static const TextStyle mobilePageTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.foregroundDark,
    letterSpacing: -0.3,
  );

  /// Mobile page scaffold subtitle
  static const TextStyle mobilePageSubtitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.foregroundTertiary,
  );
}
