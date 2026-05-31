import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_draft.dart';
import 'package:likha/presentation/widgets/shared/cards/base_action_card.dart';

/// Read-only view of one question in the desktop assessment builder.
class AssessmentQuestionCardDesktop extends StatelessWidget {
  final QuestionDraft draft;
  final int index;
  final bool isReorderMode;
  final void Function(int) onEdit;
  final void Function(int) onDelete;
  final void Function(int) onMove;

  const AssessmentQuestionCardDesktop({
    super.key,
    required this.draft,
    required this.index,
    required this.isReorderMode,
    required this.onEdit,
    required this.onDelete,
    required this.onMove,
  });

  String _typeLabel() => switch (draft.type) {
        'multiple_choice' => 'Multiple Choice',
        'identification' => 'Identification',
        'enumeration' => 'Enumeration',
        'essay' => 'Essay',
        _ => draft.type,
      };

  
  @override
  Widget build(BuildContext context) {
    return BaseActionCard(
      title: draft.questionText.isEmpty ? '(empty question)' : draft.questionText,
      subtitle: '${_typeLabel()} • ${draft.points} pt${draft.points != 1 ? 's' : ''}',
      icon: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.borderLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${index + 1}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.accentCharcoal,
          ),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      actions: isReorderMode
          ? [
              IconButton(
                icon: const Icon(Icons.swap_vert_rounded, size: 20),
                onPressed: () => onMove(index),
                tooltip: 'Move',
                color: AppColors.foregroundSecondary,
              ),
            ]
          : [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => onEdit(index),
                tooltip: 'Edit',
                color: AppColors.foregroundSecondary,
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => onDelete(index),
                tooltip: 'Remove',
                color: AppColors.semanticError,
              ),
            ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnswerPreview(),
        ],
      ),
    );
  }

  Widget _buildAnswerPreview() {
    if (draft.type == 'multiple_choice' && draft.choices.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          ...draft.choices.take(3).map(
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
                          choice.text.isEmpty ? '(empty)' : choice.text,
                          style: TextStyle(
                            fontSize: 12,
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
          if (draft.choices.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${draft.choices.length - 3} more',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.foregroundTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      );
    }

    if (draft.type == 'identification' &&
        draft.acceptableAnswers.isNotEmpty) {
      final nonEmpty =
          draft.acceptableAnswers.where((a) => a.isNotEmpty).toList();
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'Answers: ${nonEmpty.take(3).join(', ')}${nonEmpty.length > 3 ? '...' : ''}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.foregroundSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    if (draft.type == 'enumeration' && draft.enumerationItems.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          ...draft.enumerationItems
              .take(2)
              .toList()
              .asMap()
              .entries
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${e.key + 1}. ${e.value.answers.where((a) => a.isNotEmpty).join(' / ')}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.foregroundSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          if (draft.enumerationItems.length > 2)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${draft.enumerationItems.length - 2} more items',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.foregroundTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      );
    }

    if (draft.type == 'essay') {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 14,
              color: AppColors.accentAmber.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            const Text(
              'Essay - manually graded',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.foregroundSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
