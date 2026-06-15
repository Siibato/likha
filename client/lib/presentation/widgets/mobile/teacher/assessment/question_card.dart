import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_answer_preview.dart';

// Backward-compatible re-exports so existing importers need no changes.
export 'package:likha/presentation/widgets/mobile/teacher/assessment/question_draft_card.dart';
export 'package:likha/presentation/widgets/mobile/teacher/assessment/question_answer_preview.dart';
export 'package:likha/presentation/widgets/mobile/teacher/assessment/question_editor_body.dart'
    show ChoiceEntry, EnumerationItemEntry, EditorStyleVariant;

/// Read-only card for a published [Question].
class QuestionCard extends StatelessWidget {
  final int index;
  final Question question;
  final bool canEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const QuestionCard({
    super.key,
    required this.index,
    required this.question,
    required this.canEdit,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = questionTypeLabel(question.questionType);
    final typeColor = questionTypeColor(question.questionType);

    return GestureDetector(
      onTap: canEdit ? onEdit : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.accentCharcoal,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(1, 1, 1, 2.5),
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(11)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundTertiary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderLight, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.foregroundPrimary,
                          fontSize: 14,
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
                          question.questionText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.foregroundDark,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            QuestionTypeChip(label: typeLabel, color: typeColor),
                            const SizedBox(width: 8),
                            Text(
                              '${question.points} pt${question.points == 1 ? '' : 's'}',
                              style: const TextStyle(
                                color: AppColors.foregroundTertiary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (canEdit) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: AppColors.foregroundSecondary,
                      ),
                      onPressed: onEdit,
                      tooltip: 'Edit question',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppColors.semanticError,
                      ),
                      onPressed: onDelete,
                      tooltip: 'Delete question',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ],
              ),
              QuestionAnswerPreview(
                questionType: question.questionType,
                choices: question.choices
                        ?.map((c) =>
                            QuestionChoicePreview(text: c.choiceText, isCorrect: c.isCorrect))
                        .toList() ??
                    [],
                answers: question.correctAnswers?.map((a) => a.answerText).toList() ?? [],
                enumerationItems: question.enumerationItems
                        ?.map((e) =>
                            e.acceptableAnswers.map((a) => a.answerText).toList())
                        .toList() ??
                    [],
                highlightCorrectChoice: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
