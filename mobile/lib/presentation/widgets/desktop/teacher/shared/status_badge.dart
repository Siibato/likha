import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// A reusable status badge widget for displaying status information
/// with consistent styling across the desktop interface.
class StatusBadge extends StatelessWidget {
  final bool isActive;
  final String activeText;
  final String inactiveText;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? activeBackgroundColor;
  final Color? inactiveBackgroundColor;
  final EdgeInsets? padding;
  final double? borderRadius;

  const StatusBadge({
    super.key,
    required this.isActive,
    required this.activeText,
    required this.inactiveText,
    this.activeColor,
    this.inactiveColor,
    this.activeBackgroundColor,
    this.inactiveBackgroundColor,
    this.padding,
    this.borderRadius,
  });

  /// Creates a published/draft status badge
  StatusBadge.published({
    super.key,
    required bool isPublished,
    this.padding,
    this.borderRadius,
  }) : isActive = isPublished,
       activeText = 'Published',
       inactiveText = 'Draft',
       activeColor = AppColors.accentCharcoal,
       inactiveColor = AppColors.foregroundTertiary,
       activeBackgroundColor = AppColors.accentCharcoal,
       inactiveBackgroundColor = AppColors.foregroundTertiary.withValues(alpha: 0.12);

  /// Creates an active/inactive status badge
  StatusBadge.active({
    super.key,
    required bool isActive,
    String? activeText,
    String? inactiveText,
    this.padding,
    this.borderRadius,
  }) : isActive = isActive,
       activeText = activeText ?? 'Active',
       inactiveText = inactiveText ?? 'Inactive',
       activeColor = AppColors.accentCharcoal,
       inactiveColor = AppColors.foregroundTertiary,
       activeBackgroundColor = AppColors.accentCharcoal,
       inactiveBackgroundColor = AppColors.foregroundTertiary.withValues(alpha: 0.12);

  /// Creates a custom status badge with specified colors
  const StatusBadge.custom({
    super.key,
    required this.isActive,
    required this.activeText,
    required this.inactiveText,
    required this.activeColor,
    required this.inactiveColor,
    required this.activeBackgroundColor,
    required this.inactiveBackgroundColor,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? (activeBackgroundColor ?? AppColors.accentCharcoal).withValues(alpha: 0.12)
              : (inactiveBackgroundColor ??
                  AppColors.foregroundTertiary.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
        ),
        child: Text(
          isActive ? activeText : inactiveText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive
                ? (activeColor ?? AppColors.accentCharcoal)
                : (inactiveColor ?? AppColors.foregroundTertiary),
          ),
        ),
      ),
    );
  }
}

/// Extension methods for creating common status badge variants
extension StatusBadgeExtensions on StatusBadge {
  /// Creates a badge for published/draft status (most common use case)
  static Widget publishedStatus(bool isPublished, {EdgeInsets? padding, double? borderRadius}) {
    return StatusBadge.published(
      isPublished: isPublished,
      padding: padding,
      borderRadius: borderRadius,
    );
  }

  /// Creates a badge for active/inactive status
  static Widget activeStatus(bool isActive, {String? activeText, String? inactiveText}) {
    return StatusBadge.active(
      isActive: isActive,
      activeText: activeText,
      inactiveText: inactiveText,
    );
  }

  /// Creates a badge for completion status
  static Widget completionStatus(bool isCompleted, {EdgeInsets? padding}) {
    return StatusBadge.custom(
      isActive: isCompleted,
      activeText: 'Completed',
      inactiveText: 'Pending',
      activeColor: AppColors.accentCharcoal,
      inactiveColor: AppColors.foregroundTertiary,
      activeBackgroundColor: AppColors.accentCharcoal.withValues(alpha: 0.12),
      inactiveBackgroundColor: AppColors.foregroundTertiary.withValues(alpha: 0.12),
      padding: padding,
    );
  }

  /// Creates a badge for submission status
  static Widget submissionStatus(bool isSubmitted, {EdgeInsets? padding}) {
    return StatusBadge.custom(
      isActive: isSubmitted,
      activeText: 'Submitted',
      inactiveText: 'Not Submitted',
      activeColor: AppColors.accentCharcoal,
      inactiveColor: AppColors.foregroundTertiary,
      activeBackgroundColor: AppColors.accentCharcoal.withValues(alpha: 0.12),
      inactiveBackgroundColor: AppColors.foregroundTertiary.withValues(alpha: 0.12),
      padding: padding,
    );
  }

  /// Creates a badge for graded status
  static Widget gradedStatus(bool isGraded, {EdgeInsets? padding}) {
    return StatusBadge.custom(
      isActive: isGraded,
      activeText: 'Graded',
      inactiveText: 'Ungraded',
      activeColor: AppColors.onAmber,
      inactiveColor: AppColors.foregroundTertiary,
      activeBackgroundColor: AppColors.accentAmber.withValues(alpha: 0.25),
      inactiveBackgroundColor: AppColors.foregroundTertiary.withValues(alpha: 0.12),
      padding: padding,
    );
  }
}
