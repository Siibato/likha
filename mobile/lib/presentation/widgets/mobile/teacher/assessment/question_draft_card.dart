import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_answer_preview.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_draft.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_edit_panel.dart';

/// Card for a draft (not-yet-published) question with inline editing.
///
/// Shows a read-only view by default; tapping the edit button switches to
/// [QuestionEditPanel] which manages its own working copy so cancelling is safe.
class QuestionDraftCard extends StatefulWidget {
  final int index;
  final QuestionDraft question;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const QuestionDraftCard({
    super.key,
    required this.index,
    required this.question,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<QuestionDraftCard> createState() => _QuestionDraftCardState();
}

class _QuestionDraftCardState extends State<QuestionDraftCard> {
  bool _isEditing = false;

  void _handleSave(QuestionDraft updated) {
    widget.question.type = updated.type;
    widget.question.questionText = updated.questionText;
    widget.question.points = updated.points;
    widget.question.isMultiSelect = updated.isMultiSelect;
    widget.question.choices = updated.choices;
    widget.question.acceptableAnswers = updated.acceptableAnswers;
    widget.question.enumerationItems = updated.enumerationItems;
    widget.onChanged();
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.accentCharcoal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        padding: const EdgeInsets.all(16),
        child: _isEditing
            ? QuestionEditPanel(
                draft: widget.question,
                index: widget.index,
                onCancel: () => setState(() => _isEditing = false),
                onSave: _handleSave,
              )
            : _buildViewMode(),
      ),
    );
  }

  Widget _buildViewMode() {
    final type = widget.question.type;
    final typeLabel = questionTypeLabel(type);
    final typeColor = questionTypeColor(type);

    return Column(
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
                  '${widget.index + 1}',
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
                    widget.question.questionText.isEmpty
                        ? '(No question text)'
                        : widget.question.questionText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.foregroundDark,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      QuestionTypeChip(label: typeLabel, color: typeColor),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.question.points} pt${widget.question.points == 1 ? '' : 's'}',
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
          ],
        ),
        QuestionAnswerPreview(
          questionType: type,
          choices: widget.question.choices
              .map((c) => QuestionChoicePreview(text: c.text, isCorrect: c.isCorrect))
              .toList(),
          answers: widget.question.acceptableAnswers.where((a) => a.isNotEmpty).toList(),
          enumerationItems: widget.question.enumerationItems
              .map((e) => e.answers.where((a) => a.isNotEmpty).toList())
              .toList(),
          highlightCorrectChoice: true,
          enumerationLimit: 3,
          showEssayHint: true,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: AppColors.foregroundSecondary,
                size: 20,
              ),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit question',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.semanticError,
                size: 20,
              ),
              onPressed: widget.onRemove,
              tooltip: 'Remove question',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
          ],
        ),
      ],
    );
  }
}
