import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import '../tokens/app_dimensions.dart';

/// A reusable info card widget for displaying simple information.
///
/// Provides a clean layout for presenting information with optional
/// icon, title, subtitle, and custom content. Used for displaying
/// status information, details, and simple data presentations.
class BaseInfoCard extends StatelessWidget {
  final Widget? icon;
  final String? title;
  final String? subtitle;
  final Widget? content;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? iconColor;
  final CrossAxisAlignment alignment;
  final bool showBorder;

  const BaseInfoCard({
    super.key,
    this.icon,
    this.title,
    this.subtitle,
    this.content,
    this.trailing,
    this.onTap,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.iconColor,
    this.alignment = CrossAxisAlignment.start,
    this.showBorder = true,
  });

  /// Creates a compact info card with minimal styling
  factory BaseInfoCard.compact({
    String? title,
    String? subtitle,
    Widget? content,
    Widget? icon,
    VoidCallback? onTap,
  }) {
    return BaseInfoCard(
      title: title,
      subtitle: subtitle,
      content: content,
      icon: icon,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
    );
  }

  /// Creates a status info card with colored icon
  factory BaseInfoCard.status({
    required String title,
    String? subtitle,
    required IconData icon,
    Color iconColor = AppColors.accentCharcoal,
    VoidCallback? onTap,
  }) {
    return BaseInfoCard(
      title: title,
      subtitle: subtitle,
      icon: Icon(icon, color: iconColor, size: 20),
      iconColor: iconColor,
      onTap: onTap,
    );
  }

  /// Creates an info card with custom content
  factory BaseInfoCard.custom({
    required Widget content,
    String? title,
    Widget? icon,
    VoidCallback? onTap,
  }) {
    return BaseInfoCard(
      title: title,
      content: content,
      icon: icon,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin ?? const EdgeInsets.only(bottom: AppDimensions.kCardListSpacing),
      padding: padding ?? const EdgeInsets.all(AppDimensions.kCardPadMd),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: showBorder
            ? Border.all(
                color: AppColors.borderLight,
                width: 1,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: alignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || icon != null) _buildHeader(),
          if (content != null) ...[
            if (title != null || icon != null) const SizedBox(height: 12),
            content!,
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

  Widget _buildHeader() {
    if (title == null && icon == null) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          icon!,
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: alignment,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foregroundDark,
                    letterSpacing: -0.2,
                  ),
                ),
              if (subtitle != null) ...[
                if (title != null) const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.foregroundSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

/// A simple info row widget for displaying key-value pairs
class BaseInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final CrossAxisAlignment alignment;
  final MainAxisAlignment mainAxisAlignment;

  const BaseInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.labelStyle,
    this.valueStyle,
    this.alignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
  });

  /// Creates a compact info row
  factory BaseInfoRow.compact({
    required String label,
    required String value,
    IconData? icon,
  }) {
    return BaseInfoRow(
      label: label,
      value: value,
      icon: icon,
      labelStyle: const TextStyle(
        fontSize: 12,
        color: AppColors.foregroundTertiary,
        fontWeight: FontWeight.w500,
      ),
      valueStyle: const TextStyle(
        fontSize: 12,
        color: AppColors.foregroundSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: alignment,
      mainAxisAlignment: mainAxisAlignment,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 16,
            color: iconColor ?? AppColors.foregroundTertiary,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: labelStyle ?? const TextStyle(
            fontSize: 13,
            color: AppColors.foregroundTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: valueStyle ?? const TextStyle(
            fontSize: 13,
            color: AppColors.foregroundDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
