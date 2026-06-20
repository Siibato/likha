import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Displays the current question type in a read-only info card.
class QuestionTypeDisplay extends StatelessWidget {
  final String questionType;

  const QuestionTypeDisplay({
    super.key,
    required this.questionType,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (questionType) {
      'multiple_choice' => 'Multiple Choice',
      'identification' => 'Identification',
      'enumeration' => 'Enumeration',
      'essay' => 'Essay',
      _ => questionType,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.foregroundSecondary, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundPrimary,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          const Text(
            'Question type cannot be changed',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.foregroundTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
