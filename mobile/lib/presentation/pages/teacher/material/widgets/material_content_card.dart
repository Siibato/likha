import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/markdown_display.dart';

/// A card displaying learning material content (title and body text).
///
/// Shows the material's title and main content text rendered as rich text.
/// Used in the material detail page for both teacher and student views.
class MaterialContentCard extends StatelessWidget {
  final String title;
  final String? contentText;

  const MaterialContentCard({
    super.key,
    required this.title,
    this.contentText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.accentCharcoal,
            ),
          ),
        ),
        // Content text (if present) - rendered as rich text
        if (contentText != null && contentText!.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: AppColors.borderLight,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: MarkdownDisplay(
              content: contentText,
            ),
          ),
      ],
    );
  }
}
