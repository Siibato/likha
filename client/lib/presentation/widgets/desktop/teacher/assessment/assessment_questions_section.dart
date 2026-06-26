import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/domain/assessments/entities/question_draft.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_add_question_form_desktop.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_question_card.dart';

class AssessmentQuestionsSection extends StatelessWidget {
  final List<Question> questions;
  final bool isAddingQuestion;
  final VoidCallback? onOpenAddForm;
  final VoidCallback? onCancelAdd;
  final void Function(QuestionDraft)? onConfirmAdd;

  const AssessmentQuestionsSection({
    super.key,
    required this.questions,
    this.isAddingQuestion = false,
    this.onOpenAddForm,
    this.onCancelAdd,
    this.onConfirmAdd,
  });

  bool get _canAdd => onOpenAddForm != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Questions (${questions.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.foregroundDark,
          ),
        ),
        const SizedBox(height: 12),
        if (questions.isEmpty && !isAddingQuestion)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Center(
              child: Text(
                _canAdd
                    ? 'No questions yet. Add your first question below.'
                    : 'No questions added yet',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.foregroundTertiary,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                AssessmentQuestionCard(
                  question: questions[index],
                  number: index + 1,
                ),
          ),
        if (isAddingQuestion && _canAdd) ...[
          const SizedBox(height: 12),
          AssessmentAddQuestionFormDesktop(
            onConfirm: onConfirmAdd!,
            onCancel: onCancelAdd!,
          ),
        ] else if (_canAdd) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenAddForm,
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
        ],
      ],
    );
  }
}
