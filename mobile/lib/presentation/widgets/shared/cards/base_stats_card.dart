import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// A reusable stats card widget for displaying metrics and data.
///
/// Provides a consistent layout for statistics with icon, title, value,
/// and optional subtitle. Used for dashboard metrics across admin and teacher interfaces.
class BaseStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double? width;
  final bool isLoading;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const BaseStatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
    this.width,
    this.isLoading = false,
    this.margin,
    this.padding,
  });

  /// Creates a stats card with default styling
  factory BaseStatsCard.standard({
    required String title,
    required String value,
    required IconData icon,
    String? subtitle,
    VoidCallback? onTap,
    double? width,
    bool isLoading = false,
  }) {
    return BaseStatsCard(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      iconColor: AppColors.accentCharcoal,
      backgroundColor: AppColors.accentCharcoal.withOpacity(0.1),
      onTap: onTap,
      width: width,
      isLoading: isLoading,
    );
  }

  /// Creates a success-themed stats card
  factory BaseStatsCard.success({
    required String title,
    required String value,
    required IconData icon,
    String? subtitle,
    VoidCallback? onTap,
    double? width,
    bool isLoading = false,
  }) {
    return BaseStatsCard(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      iconColor: AppColors.semanticSuccessAlt,
      backgroundColor: AppColors.semanticSuccessAlt.withOpacity(0.1),
      onTap: onTap,
      width: width,
      isLoading: isLoading,
    );
  }

  /// Creates a warning-themed stats card
  factory BaseStatsCard.warning({
    required String title,
    required String value,
    required IconData icon,
    String? subtitle,
    VoidCallback? onTap,
    double? width,
    bool isLoading = false,
  }) {
    return BaseStatsCard(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      iconColor: AppColors.accentAmber,
      backgroundColor: AppColors.accentAmber.withOpacity(0.1),
      onTap: onTap,
      width: width,
      isLoading: isLoading,
    );
  }

  /// Creates an error-themed stats card
  factory BaseStatsCard.error({
    required String title,
    required String value,
    required IconData icon,
    String? subtitle,
    VoidCallback? onTap,
    double? width,
    bool isLoading = false,
  }) {
    return BaseStatsCard(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      iconColor: AppColors.semanticErrorDark,
      backgroundColor: AppColors.semanticErrorDark.withOpacity(0.1),
      onTap: onTap,
      width: width,
      isLoading: isLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.foregroundPrimary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: iconColor ?? AppColors.foregroundPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        icon,
                        size: 24,
                        color: iconColor ?? AppColors.foregroundPrimary,
                      ),
              ),
              const Spacer(),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.foregroundTertiary,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.foregroundTertiary,
            ),
          ),
          const SizedBox(height: 4),
          isLoading
              ? Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foregroundPrimary,
                  ),
                ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.foregroundTertiary,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// A row of stats cards with responsive layout
class BaseStatsRow extends StatelessWidget {
  final List<BaseStatsCard> cards;
  final double spacing;
  final double runSpacing;
  final double? cardWidth;

  const BaseStatsRow({
    super.key,
    required this.cards,
    this.spacing = 16,
    this.runSpacing = 16,
    this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: cards.map((card) {
        return SizedBox(
          width: cardWidth ?? 280,
          child: card,
        );
      }).toList(),
    );
  }
}
