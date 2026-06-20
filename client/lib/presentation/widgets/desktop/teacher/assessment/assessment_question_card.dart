import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_type_badge.dart';

class AssessmentQuestionCard extends StatelessWidget {
  final Question question;
  final int number;

  const AssessmentQuestionCard({
    super.key,
    required this.question,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foregroundSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AssessmentTypeBadge(type: question.questionType),
                    const SizedBox(width: 8),
                    Text(
                      '${question.points} pt${question.points != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.foregroundTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  question.questionText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.foregroundDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
