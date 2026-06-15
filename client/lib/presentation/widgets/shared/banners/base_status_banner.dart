import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Status banner variants for different types of notifications
enum BaseStatusBannerVariant {
  info,
  warning,
  success,
  error,
  neutral,
}

/// A reusable status banner widget for displaying notifications and alerts.
///
/// Provides a consistent layout for status messages with optional icon,
/// title, message, and action buttons. Used for displaying assessment status,
/// assignment feedback, and other important notifications.
class BaseStatusBanner extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData? icon;
  final BaseStatusBannerVariant variant;
  final VoidCallback? onTap;
  final Widget? action;
  final EdgeInsets? margin;
  final bool showBorder;

  const BaseStatusBanner({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.variant = BaseStatusBannerVariant.info,
    this.onTap,
    this.action,
    this.margin,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor, borderColor) = _getColors();

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: showBorder
            ? Border.all(
                color: borderColor,
                width: 1,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: fgColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null) ...[
                        Text(
                          title!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: fgColor,
                          ),
                        ),
                        if (message != null) const SizedBox(height: 4),
                      ],
                      if (message != null)
                        Text(
                          message!,
                          style: TextStyle(
                            fontSize: 13,
                            color: fgColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(width: 12),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color, Color) _getColors() {
    switch (variant) {
      case BaseStatusBannerVariant.info:
        return (AppColors.accentAmber.withValues(alpha: 0.1), 
                AppColors.accentAmber, 
                AppColors.accentAmber.withValues(alpha: 0.3));
      case BaseStatusBannerVariant.warning:
        return (AppColors.accentAmber.withValues(alpha: 0.1), 
                AppColors.accentAmber, 
                AppColors.accentAmber.withValues(alpha: 0.3));
      case BaseStatusBannerVariant.success:
        return (AppColors.semanticSuccessAlt.withValues(alpha: 0.1), 
                AppColors.semanticSuccessAlt, 
                AppColors.semanticSuccessAlt.withValues(alpha: 0.3));
      case BaseStatusBannerVariant.error:
        return (AppColors.semanticError.withValues(alpha: 0.1), 
                AppColors.semanticError, 
                AppColors.semanticError.withValues(alpha: 0.3));
      case BaseStatusBannerVariant.neutral:
        return (AppColors.backgroundTertiary, 
                AppColors.foregroundDark, 
                AppColors.borderLight);
    }
  }
}
