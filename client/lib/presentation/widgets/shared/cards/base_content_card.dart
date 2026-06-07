import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import '../tokens/app_dimensions.dart';

/// A reusable content card widget for displaying rich content.
///
/// Provides a flexible layout for content-heavy cards with title,
/// subtitle, rich text content, media, and optional actions.
/// Used for material content, articles, descriptions, and detailed information.
class BaseContentCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? content;
  final List<Widget> actions;
  final Widget? header;
  final Widget? footer;
  final VoidCallback? onTap;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final EdgeInsets? contentPadding;
  final Color? backgroundColor;
  final Color? titleColor;
  final CrossAxisAlignment alignment;
  final bool showBorder;
  final double? contentMaxHeight;
  final bool scrollable;

  const BaseContentCard({
    super.key,
    this.title,
    this.subtitle,
    this.content,
    this.actions = const [],
    this.header,
    this.footer,
    this.onTap,
    this.margin,
    this.padding,
    this.contentPadding,
    this.backgroundColor,
    this.titleColor,
    this.alignment = CrossAxisAlignment.start,
    this.showBorder = true,
    this.contentMaxHeight,
    this.scrollable = false,
  });

  /// Creates a simple content card with title and content
  factory BaseContentCard.simple({
    required String title,
    required Widget content,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return BaseContentCard(
      title: title,
      subtitle: subtitle,
      content: content,
      onTap: onTap,
    );
  }

  /// Creates a material content card with rich text
  factory BaseContentCard.material({
    required String title,
    String? contentText,
    List<Widget> actions = const [],
    VoidCallback? onTap,
  }) {
    return BaseContentCard(
      title: title,
      content: contentText != null
          ? Text(
              contentText,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.foregroundSecondary,
                height: 1.5,
              ),
            )
          : null,
      actions: actions,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
    );
  }

  /// Creates a scrollable content card for long content
  factory BaseContentCard.scrollable({
    required String title,
    required Widget content,
    String? subtitle,
    double? maxHeight,
    List<Widget> actions = const [],
  }) {
    return BaseContentCard(
      title: title,
      subtitle: subtitle,
      content: content,
      actions: actions,
      contentMaxHeight: maxHeight,
      scrollable: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin ?? const EdgeInsets.only(bottom: AppDimensions.kCardListSpacing),
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
          if (header != null) header!,
          if (title != null || subtitle != null) _buildHeader(),
          if (content != null) _buildContent(),
          if (actions.isNotEmpty) _buildActions(),
          if (footer != null) footer!,
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
    return Padding(
      padding: padding ?? const EdgeInsets.all(AppDimensions.kCardPadMd),
      child: Column(
        crossAxisAlignment: alignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Text(
              title!,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: titleColor ?? AppColors.accentCharcoal,
                letterSpacing: -0.3,
              ),
            ),
          if (subtitle != null) ...[
            if (title != null) const SizedBox(height: 8),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.foregroundTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    final contentWidget = content!;

    if (scrollable || contentMaxHeight != null) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: contentMaxHeight ?? 300,
        ),
        child: SingleChildScrollView(
          padding: contentPadding ?? const EdgeInsets.symmetric(
            horizontal: AppDimensions.kCardPadMd,
            vertical: 8,
          ),
          child: contentWidget,
        ),
      );
    }

    return Padding(
      padding: contentPadding ?? const EdgeInsets.symmetric(
        horizontal: AppDimensions.kCardPadMd,
        vertical: 8,
      ),
      child: contentWidget,
    );
  }

  Widget _buildActions() {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.kCardPadMd),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: actions
            .map((action) => [
                action,
                if (action != actions.last) const SizedBox(width: 8),
              ])
            .expand((e) => e)
            .toList(),
      ),
    );
  }
}

/// A sectioned content card for organizing content into sections
class BaseSectionedContentCard extends StatelessWidget {
  final String? title;
  final List<BaseContentSection> sections;
  final List<Widget> actions;
  final VoidCallback? onTap;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const BaseSectionedContentCard({
    super.key,
    this.title,
    required this.sections,
    this.actions = const [],
    this.onTap,
    this.margin,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return BaseContentCard(
      title: title,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: sections
            .map((section) => [
                section,
                if (section != sections.last) const SizedBox(height: 16),
              ])
            .expand((e) => e)
            .toList(),
      ),
      actions: actions,
      onTap: onTap,
      margin: margin,
      padding: padding,
      backgroundColor: backgroundColor,
    );
  }
}

/// A content section for use in BaseSectionedContentCard
class BaseContentSection extends StatelessWidget {
  final String? title;
  final Widget content;
  final EdgeInsets? padding;
  final bool showBorder;

  const BaseContentSection({
    super.key,
    this.title,
    required this.content,
    this.padding,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: showBorder
          ? BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderLight,
                width: 1,
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.foregroundDark,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
          ],
          content,
        ],
      ),
    );
  }
}
