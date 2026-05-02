import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import '../tokens/app_text_styles.dart';

/// A reusable typography block for combining title, subtitle, and body text.
///
/// Use [onDark] when placing inside dark or accentFill cards.
class TextBlock extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? body;
  final bool onDark;

  const TextBlock._({
    this.title,
    this.subtitle,
    this.body,
    this.onDark = false,
  });

  factory TextBlock.titleSubtitle(
    String title,
    String subtitle, {
    bool onDark = false,
  }) {
    return TextBlock._(title: title, subtitle: subtitle, onDark: onDark);
  }

  factory TextBlock.titleParagraph(
    String title,
    String body, {
    bool onDark = false,
  }) {
    return TextBlock._(title: title, body: body, onDark: onDark);
  }

  factory TextBlock.subtitleParagraph(
    String subtitle,
    String body, {
    bool onDark = false,
  }) {
    return TextBlock._(subtitle: subtitle, body: body, onDark: onDark);
  }

  factory TextBlock.titleSubtitleParagraph(
    String title,
    String subtitle,
    String body, {
    bool onDark = false,
  }) {
    return TextBlock._(
      title: title,
      subtitle: subtitle,
      body: body,
      onDark: onDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = onDark ? Colors.white : AppColors.foregroundDark;
    final subtitleColor =
        onDark ? Colors.white.withValues(alpha: 0.7) : AppColors.foregroundTertiary;
    final bodyColor =
        onDark ? Colors.white.withValues(alpha: 0.85) : AppColors.foregroundSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: AppTextStyles.cardTitleLg.copyWith(color: titleColor),
          ),
          if (subtitle != null || body != null) const SizedBox(height: 4),
        ],
        if (subtitle != null) ...[
          Text(
            subtitle!,
            style: AppTextStyles.cardSubtitleMd.copyWith(color: subtitleColor),
          ),
          if (body != null) const SizedBox(height: 6),
        ],
        if (body != null)
          Text(
            body!,
            style: AppTextStyles.dialogBody.copyWith(color: bodyColor),
          ),
      ],
    );
  }
}
