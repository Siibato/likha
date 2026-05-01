import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/tokens/app_text_styles.dart';

/// Severity level for [StatusBanner].
enum BannerSeverity {
  /// Amber — caution, returned items, warnings.
  warning,

  /// Blue/secondary — neutral info.
  info,

  /// Green — success, submitted, graded.
  success,

  /// Red — error, critical alerts.
  error,
}

/// Shared banner widget for Likha LMS.
///
/// Consolidates the 6+ separate banner widgets that share identical structure:
/// - `WarningBanner` (teacher/grade)
/// - `AssignmentReturnedBanner` (student/assignment)
/// - `AssignmentSubmittedBanner` (student/assignment)
/// - `assessment_status_banner.dart` (student/assessment)
/// - `general_average_banner.dart` (student/grade)
/// - Inline lockout banner in `login_password_page`
///
/// Usage:
/// ```dart
/// StatusBanner(
///   severity: BannerSeverity.warning,
///   message: 'Grading period is not yet configured.',
/// )
///
/// StatusBanner(
///   severity: BannerSeverity.warning,
///   title: 'Returned for Revision',
///   message: feedback,
///   icon: Icons.replay_rounded,
/// )
/// ```
class StatusBanner extends StatelessWidget {
  final BannerSeverity severity;
  final String message;
  final String? title;
  final IconData? icon;
  final Widget? action;
  final EdgeInsets? padding;

  const StatusBanner({
    super.key,
    required this.severity,
    required this.message,
    this.title,
    this.icon,
    this.action,
    this.padding,
  });

  _BannerTheme get _theme => switch (severity) {
        BannerSeverity.warning => _BannerTheme(
            background: AppColors.accentAmberSurface,
            border: AppColors.accentAmber,
            iconColor: AppColors.accentAmberBorder,
            textColor: AppColors.accentAmberBorder,
            defaultIcon: Icons.warning_amber_rounded,
          ),
        BannerSeverity.info => _BannerTheme(
            background: AppColors.backgroundTertiary,
            border: AppColors.borderLight,
            iconColor: AppColors.foregroundSecondary,
            textColor: AppColors.foregroundSecondary,
            defaultIcon: Icons.info_outline_rounded,
          ),
        BannerSeverity.success => _BannerTheme(
            background: AppColors.semanticSuccessBackground,
            border: AppColors.semanticSuccess,
            iconColor: AppColors.semanticSuccess,
            textColor: AppColors.semanticSuccess,
            defaultIcon: Icons.check_circle_outline_rounded,
          ),
        BannerSeverity.error => _BannerTheme(
            background: AppColors.semanticErrorBackground,
            border: AppColors.semanticError,
            iconColor: AppColors.semanticErrorDark,
            textColor: AppColors.semanticErrorDark,
            defaultIcon: Icons.error_outline_rounded,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final theme = _theme;
    final resolvedIcon = icon ?? theme.defaultIcon;
    final hasTitle = title != null && title!.isNotEmpty;

    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border, width: 1),
      ),
      child: hasTitle
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(resolvedIcon, color: theme.iconColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title!,
                        style: AppTextStyles.cardTitleSm.copyWith(
                          color: AppColors.foregroundPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: AppTextStyles.cardSubtitleMd.copyWith(
                    color: AppColors.foregroundPrimary,
                    height: 1.4,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 12),
                  action!,
                ],
              ],
            )
          : Row(
              children: [
                Icon(resolvedIcon, color: theme.iconColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: AppTextStyles.cardSubtitleMd.copyWith(
                      color: theme.textColor,
                      height: 1.4,
                    ),
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(width: 12),
                  action!,
                ],
              ],
            ),
    );
  }
}

class _BannerTheme {
  final Color background;
  final Color border;
  final Color iconColor;
  final Color textColor;
  final IconData defaultIcon;

  const _BannerTheme({
    required this.background,
    required this.border,
    required this.iconColor,
    required this.textColor,
    required this.defaultIcon,
  });
}
