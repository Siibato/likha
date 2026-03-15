import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/base_card.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/markdown_display.dart';

class AssignmentInstructionsCard extends StatelessWidget {
  final String instructions;
  final int totalPoints;

  const AssignmentInstructionsCard({
    super.key,
    required this.instructions,
    required this.totalPoints,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Instructions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202020),
                  letterSpacing: -0.4,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.backgroundTertiary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$totalPoints pts',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: const Color(0xFFF0F0F0),
          ),
          const SizedBox(height: 12),
          MarkdownDisplay(
            content: instructions,
          ),
        ],
      ),
    );
  }
}