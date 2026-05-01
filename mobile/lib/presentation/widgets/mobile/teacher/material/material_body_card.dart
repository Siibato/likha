import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/cards/base_card.dart';
import 'package:likha/presentation/widgets/shared/cards/markdown_display.dart';

/// Card showing the rich-text body content of a learning material.
///
/// Renders a "Content" section label followed by the [contentText]
/// via [MarkdownDisplay].
class MaterialBodyCard extends StatelessWidget {
  final String? contentText;

  const MaterialBodyCard({super.key, required this.contentText});

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Content',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
          MarkdownDisplay(content: contentText),
        ],
      ),
    );
  }
}
