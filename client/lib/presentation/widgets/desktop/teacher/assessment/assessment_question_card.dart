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
                _buildAnswerPreview(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerPreview() {
    if (question.questionType == 'multiple_choice' &&
        question.choices != null &&
        question.choices!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          ...question.choices!.take(3).map(
                (choice) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Icon(
                        choice.isCorrect
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 12,
                        color: choice.isCorrect
                            ? AppColors.semanticSuccessAlt
                            : AppColors.foregroundLight,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          choice.choiceText.isEmpty ? '(empty)' : choice.choiceText,
                          style: TextStyle(
                            fontSize: 13,
                            color: choice.isCorrect
                                ? AppColors.accentCharcoal
                                : AppColors.foregroundSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (question.choices!.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${question.choices!.length - 3} more',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.foregroundTertiary,
                ),
              ),
            ),
        ],
      );
    }

    if (question.questionType == 'identification' &&
        question.correctAnswers != null &&
        question.correctAnswers!.isNotEmpty) {
      final nonEmpty = question.correctAnswers!
          .where((a) => a.answerText.isNotEmpty)
          .map((a) => a.answerText)
          .toList();
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'Answers: ${nonEmpty.take(3).join(', ')}${nonEmpty.length > 3 ? '...' : ''}',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.foregroundSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    if (question.questionType == 'enumeration' &&
        question.enumerationItems != null &&
        question.enumerationItems!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          ...question.enumerationItems!.toList().asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${e.key + 1}. ${e.value.acceptableAnswers.where((a) => a.answerText.isNotEmpty).map((a) => a.answerText).join(' / ')}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.foregroundSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
        ],
      );
    }

    if (question.questionType == 'essay') {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_note_rounded,
                size: 14,
                color: AppColors.foregroundSecondary,
              ),
              SizedBox(width: 6),
              Text(
                'Manually graded',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.foregroundSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
