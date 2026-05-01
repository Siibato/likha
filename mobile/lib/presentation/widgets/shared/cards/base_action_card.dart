import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import '../tokens/app_dimensions.dart';
import '../forms/styled_button.dart';

/// A reusable action card widget with primary action buttons.
///
/// Provides a consistent layout for cards that need to display content
/// along with primary action buttons. Used for interactive cards like
/// confirmations, selections, and actions that require user input.
class BaseActionCard extends StatelessWidget {
  final Widget child;
  final List<Widget> actions;
  final String? title;
  final String? subtitle;
  final Widget? icon;
  final VoidCallback? onTap;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final EdgeInsets? actionsPadding;
  final Color? backgroundColor;
  final CrossAxisAlignment alignment;
  final bool showDivider;
  final MainAxisAlignment actionAlignment;

  const BaseActionCard({
    super.key,
    required this.child,
    this.actions = const [],
    this.title,
    this.subtitle,
    this.icon,
    this.onTap,
    this.margin,
    this.padding,
    this.actionsPadding,
    this.backgroundColor,
    this.alignment = CrossAxisAlignment.start,
    this.showDivider = true,
    this.actionAlignment = MainAxisAlignment.end,
  });

  /// Creates a simple action card with a single primary action
  factory BaseActionCard.single({
    required Widget child,
    required String primaryActionText,
    required VoidCallback onPrimaryAction,
    String? title,
    Widget? icon,
    VoidCallback? onTap,
    StyledButtonVariant primaryVariant = StyledButtonVariant.primary,
  }) {
    return BaseActionCard(
      title: title,
      icon: icon,
      onTap: onTap,
      child: child,
      actions: [
        StyledButton(
          text: primaryActionText,
          isLoading: false,
          onPressed: onPrimaryAction,
          variant: primaryVariant,
          fullWidth: false,
        ),
      ],
    );
  }

  /// Creates a confirmation action card with confirm/cancel actions
  factory BaseActionCard.confirmation({
    required Widget child,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    String? title,
    Widget? icon,
    bool isDestructive = false,
  }) {
    return BaseActionCard(
      title: title,
      icon: icon,
      child: child,
      actions: [
        if (onCancel != null)
          StyledButton(
            text: cancelText,
            isLoading: false,
            onPressed: onCancel,
            variant: StyledButtonVariant.outlined,
            fullWidth: false,
          ),
        const SizedBox(width: 8),
        StyledButton(
          text: confirmText,
          isLoading: false,
          onPressed: onConfirm,
          variant: isDestructive ? StyledButtonVariant.destructive : StyledButtonVariant.primary,
          fullWidth: false,
        ),
      ],
    );
  }

  /// Creates a selection action card with select/cancel actions
  factory BaseActionCard.selection({
    required Widget child,
    required VoidCallback onSelect,
    VoidCallback? onCancel,
    String selectText = 'Select',
    String cancelText = 'Cancel',
    String? title,
    Widget? icon,
  }) {
    return BaseActionCard(
      title: title,
      icon: icon,
      child: child,
      actions: [
        if (onCancel != null)
          StyledButton(
            text: cancelText,
            isLoading: false,
            onPressed: onCancel,
            variant: StyledButtonVariant.outlined,
            fullWidth: false,
          ),
        const SizedBox(width: 8),
        StyledButton(
          text: selectText,
          isLoading: false,
          onPressed: onSelect,
          variant: StyledButtonVariant.primary,
          fullWidth: false,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin ?? const EdgeInsets.only(bottom: AppDimensions.kCardListSpacing),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: alignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || icon != null)
            _buildHeader(),
          Padding(
            padding: padding ?? const EdgeInsets.all(AppDimensions.kCardPadMd),
            child: child,
          ),
          if (actions.isNotEmpty) ...[
            if (showDivider)
              Container(
                height: 1,
                color: AppColors.borderLight,
                margin: const EdgeInsets.symmetric(horizontal: AppDimensions.kCardPadMd),
              ),
            _buildActions(),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.kCardPadMd,
        AppDimensions.kCardPadMd,
        AppDimensions.kCardPadMd,
        0,
      ),
      child: Row(
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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foregroundDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                if (subtitle != null) ...[
                  if (title != null) const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.foregroundTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: actionsPadding ?? const EdgeInsets.all(AppDimensions.kCardPadMd),
      child: Row(
        mainAxisAlignment: actionAlignment,
        children: actions,
      ),
    );
  }
}

/// A quick action card with a single tap action
class BaseQuickActionCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final String? title;
  final IconData? actionIcon;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? actionColor;

  const BaseQuickActionCard({
    super.key,
    required this.child,
    required this.onTap,
    this.title,
    this.actionIcon,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: margin ?? const EdgeInsets.only(bottom: AppDimensions.kCardListSpacing),
          padding: padding ?? const EdgeInsets.all(AppDimensions.kCardPadMd),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 4),
                    child,
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                actionIcon ?? Icons.chevron_right_rounded,
                size: 20,
                color: actionColor ?? AppColors.foregroundTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
