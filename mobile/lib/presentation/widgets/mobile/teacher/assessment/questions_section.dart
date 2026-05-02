import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_card.dart';

class QuestionsSection extends StatelessWidget {
  final List<Question> questions;
  final bool canEdit;
  final bool isPublished;
  final int submissionCount;
  final VoidCallback? onAddQuestion;
  final Function(Question)? onEditQuestion;
  final Function(Question)? onDeleteQuestion;
  final VoidCallback? onEnterReorderMode;

  const QuestionsSection({
    super.key,
    required this.questions,
    required this.canEdit,
    required this.isPublished,
    required this.submissionCount,
    this.onAddQuestion,
    this.onEditQuestion,
    this.onDeleteQuestion,
    this.onEnterReorderMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Questions (${questions.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foregroundDark,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (canEdit) ...[
                ElevatedButton.icon(
                  onPressed: onAddQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentCharcoal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Add',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (questions.length > 1 && onEnterReorderMode != null)
                  OutlinedButton.icon(
                    onPressed: onEnterReorderMode,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentCharcoal,
                      side: const BorderSide(
                        color: AppColors.accentCharcoal,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.reorder_rounded, size: 16),
                    label: const Text(
                      'Reorder',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ],
          ),
          if (submissionCount > 0 && canEdit) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentAmberSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.accentAmberBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.accentAmber,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This assessment has $submissionCount submission(s). Editing questions may affect scores.',
                      style: const TextStyle(
                        color: AppColors.accentAmberBorder,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isPublished) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.borderLight,
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                   Icon(
                    Icons.lock_rounded,
                    color: AppColors.foregroundDark,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This assessment is published. Questions and details can no longer be edited.',
                      style: TextStyle(
                        color: AppColors.foregroundDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (questions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundTertiary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.quiz_outlined,
                        size: 48,
                        color: AppColors.foregroundLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No questions added yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.foregroundTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return QuestionCard(
                index: index,
                question: question,
                canEdit: canEdit,
                onEdit: canEdit && onEditQuestion != null
                    ? () => onEditQuestion!(question)
                    : null,
                onDelete: canEdit && onDeleteQuestion != null
                    ? () => onDeleteQuestion!(question)
                    : null,
              );
            }),
        ],
      ),
    );
  }
}