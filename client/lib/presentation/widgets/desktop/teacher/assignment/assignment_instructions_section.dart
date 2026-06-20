import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/cards/markdown_display.dart';

/// Section displaying assignment instructions.
class AssignmentInstructionsSection extends StatelessWidget {
  final String instructions;

  const AssignmentInstructionsSection({super.key, required this.instructions});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instructions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderLight),
          const SizedBox(height: 12),
          if (instructions.isNotEmpty)
            MarkdownDisplay(content: instructions)
          else
            const Text(
              'No instructions provided',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.foregroundTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}
