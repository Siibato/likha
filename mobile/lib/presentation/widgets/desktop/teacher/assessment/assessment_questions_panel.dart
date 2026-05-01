import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_add_question_form_desktop.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_question_card_desktop.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_question_edit_form_desktop.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_draft.dart';

/// Right panel of the desktop assessment builder showing all question cards.
class AssessmentQuestionsPanel extends StatelessWidget {
  final List<QuestionDraft> questions;
  final bool isAddingQuestion;
  final bool isReorderMode;
  final bool isSaving;
  final int? editingQuestionIndex;
  final VoidCallback onEnterReorderMode;
  final VoidCallback onExitReorderMode;
  final VoidCallback onOpenAddForm;
  final VoidCallback onCancelAdd;
  final void Function(int) onEditQuestion;
  final void Function(int) onDeleteQuestion;
  final void Function(int) onMoveQuestion;
  final void Function(QuestionDraft) onConfirmAdd;
  final void Function(int index, QuestionDraft updated) onSaveEdit;
  final VoidCallback onCancelEdit;

  const AssessmentQuestionsPanel({
    super.key,
    required this.questions,
    required this.isAddingQuestion,
    required this.isReorderMode,
    required this.isSaving,
    required this.editingQuestionIndex,
    required this.onEnterReorderMode,
    required this.onExitReorderMode,
    required this.onOpenAddForm,
    required this.onCancelAdd,
    required this.onEditQuestion,
    required this.onDeleteQuestion,
    required this.onMoveQuestion,
    required this.onConfirmAdd,
    required this.onSaveEdit,
    required this.onCancelEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(24),
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
                    color: AppColors.accentCharcoal,
                  ),
                ),
              ),
              if (isReorderMode)
                TextButton.icon(
                  onPressed: onExitReorderMode,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Done'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentCharcoal,
                  ),
                )
              else if (questions.length > 1)
                TextButton.icon(
                  onPressed: onEnterReorderMode,
                  icon: const Icon(Icons.swap_vert_rounded, size: 18),
                  label: const Text('Reorder'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.foregroundSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (questions.isEmpty && !isAddingQuestion)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              child: const Text(
                'No questions yet. Add your first question below.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.foregroundTertiary,
                ),
              ),
            ),

          ...List.generate(questions.length, (i) {
            final q = questions[i];
            if (editingQuestionIndex == i) {
              return AssessmentQuestionEditFormDesktop(
                key: ValueKey('edit_$i'),
                draft: q,
                onSave: (updated) => onSaveEdit(i, updated),
                onCancel: onCancelEdit,
              );
            }
            return AssessmentQuestionCardDesktop(
              key: ValueKey('card_$i'),
              draft: q,
              index: i,
              isReorderMode: isReorderMode,
              onEdit: onEditQuestion,
              onDelete: onDeleteQuestion,
              onMove: onMoveQuestion,
            );
          }),

          if (isAddingQuestion)
            AssessmentAddQuestionFormDesktop(
              onConfirm: onConfirmAdd,
              onCancel: onCancelAdd,
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      isSaving || isReorderMode ? null : onOpenAddForm,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add Question'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentCharcoal,
                    side: const BorderSide(color: AppColors.borderLight),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
