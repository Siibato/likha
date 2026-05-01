import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_card.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_draft.dart';

class AssessmentQuestionsSection extends StatelessWidget {
  final List<QuestionDraft> questions;
  final bool isLoading;
  final bool isReorderMode;
  final VoidCallback? onAddQuestion;
  final ValueChanged<int> onRemoveQuestion;
  final VoidCallback onQuestionsChanged;
  final VoidCallback? onSaveQuestions;
  final VoidCallback? onEnterReorderMode;
  final VoidCallback? onExitReorderMode;
  final Function(int)? onReorderQuestion;

  const AssessmentQuestionsSection({
    super.key,
    required this.questions,
    required this.isLoading,
    this.isReorderMode = false,
    this.onAddQuestion,
    required this.onRemoveQuestion,
    required this.onQuestionsChanged,
    this.onSaveQuestions,
    this.onEnterReorderMode,
    this.onExitReorderMode,
    this.onReorderQuestion,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isReorderMode) ...[
          Container(
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
                    Text(
                      'Questions (${questions.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foregroundDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onExitReorderMode,
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onExitReorderMode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentCharcoal,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Done'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...questions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final question = entry.value;
                  return GestureDetector(
                    onTap: onReorderQuestion != null ? () => onReorderQuestion!(index) : null,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.accentCharcoal,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.foregroundPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  question.questionText.isEmpty
                                      ? '(untitled)'
                                      : question.questionText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.foregroundDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Chip(
                                  label: Text(
                                    question.type,
                                    style: const TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.foregroundTertiary,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ] else ...[
          if (questions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderLight,
                  width: 1,
                ),
              ),
              child: const Center(
                child: Text(
                  'No questions added yet.\nTap the button below to add a question.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.foregroundTertiary,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ...questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return QuestionDraftCard(
              index: index,
              question: question,
              onRemove: () => onRemoveQuestion(index),
              onChanged: onQuestionsChanged,
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onAddQuestion,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add Question'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentCharcoal,
                    side: const BorderSide(
                      color: AppColors.borderLight,
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (questions.length > 1 && onEnterReorderMode != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEnterReorderMode,
                    icon: const Icon(Icons.reorder_rounded, size: 20),
                    label: const Text('Reorder'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentCharcoal,
                      side: const BorderSide(
                        color: AppColors.borderLight,
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}