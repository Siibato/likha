import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/presentation/pages/teacher/widgets/question_draft.dart';
import 'package:likha/presentation/pages/teacher/widgets/question_type_dropdown.dart';
import 'package:likha/presentation/pages/teacher/widgets/question_editor_body.dart';
export 'package:likha/presentation/pages/teacher/widgets/question_editor_body.dart'
    show ChoiceEntry, EnumerationItemEntry, EditorStyleVariant;

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

  String _questionTypeLabel(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'identification':
        return 'Identification';
      case 'enumeration':
        return 'Enumeration';
      default:
        return type;
    }
  }

  Color _questionTypeColor(String type) {
    switch (type) {
      case 'multiple_choice':
        return const Color(0xFF2B2B2B);
      case 'identification':
        return const Color(0xFF666666);
      case 'enumeration':
        return const Color(0xFF999999);
      default:
        return const Color(0xFF999999);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canEdit ? onEdit : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(1, 1, 1, 2.5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
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
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2B2B2B),
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
                            color: Color(0xFF202020),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _QuestionTypeChip(
                              label: _questionTypeLabel(question.questionType),
                              color: _questionTypeColor(question.questionType),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${question.points} pt${question.points == 1 ? '' : 's'}',
                              style: const TextStyle(
                                color: Color(0xFF999999),
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
                        color: Color(0xFF666666),
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
                        color: Color(0xFFEF5350),
                      ),
                      onPressed: onDelete,
                      tooltip: 'Delete question',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ],
              ),
              if (question.questionType == 'multiple_choice' &&
                  question.choices != null &&
                  question.choices!.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...question.choices!.take(4).map(
                      (choice) => Padding(
                        padding: const EdgeInsets.only(left: 44, top: 4),
                        child: Row(
                          children: [
                            Icon(
                              choice.isCorrect
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              size: 14,
                              color: choice.isCorrect
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFCCCCCC),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                choice.choiceText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF666666),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                if (question.choices!.length > 4)
                  Padding(
                    padding: const EdgeInsets.only(left: 44, top: 6),
                    child: Text(
                      '+${question.choices!.length - 4} more choices',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
              if (question.questionType == 'identification' &&
                  question.correctAnswers != null &&
                  question.correctAnswers!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 44),
                  child: Text(
                    'Answers: ${question.correctAnswers!.map((a) => a.answerText).join(', ')}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (question.questionType == 'enumeration' &&
                  question.enumerationItems != null &&
                  question.enumerationItems!.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...question.enumerationItems!.take(4).toList().asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(left: 44, top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key + 1}.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF999999),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            entry.value.acceptableAnswers
                                .map((a) => a.answerText)
                                .join(' / '),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF666666),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (question.enumerationItems!.length > 4)
                  Padding(
                    padding: const EdgeInsets.only(left: 44, top: 6),
                    child: Text(
                      '+${question.enumerationItems!.length - 4} more items',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionTypeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _QuestionTypeChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

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
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Text(
                'Question ${widget.index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202020),
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF5350),
                  size: 20,
                ),
                onPressed: widget.onRemove,
                tooltip: 'Remove question',
              ),
            ],
          ),
          const SizedBox(height: 12),
          QuestionTypeDropdown(
            value: widget.question.type,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  widget.question.type = value;
                });
                widget.onChanged();
              }
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: widget.question.questionText,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2B2B2B),
            ),
            decoration: InputDecoration(
              labelText: 'Question Text',
              labelStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xFF999999),
              ),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2B2B2B),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (value) {
              widget.question.questionText = value;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: widget.question.points.toString(),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2B2B2B),
            ),
            decoration: InputDecoration(
              labelText: 'Points',
              labelStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xFF999999),
              ),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2B2B2B),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (value) {
              widget.question.points = int.tryParse(value) ?? 1;
            },
          ),
          const SizedBox(height: 16),
          if (widget.question.type == 'multiple_choice')
            QuestionEditorBody(
              questionType: 'multiple_choice',
              choices: widget.question.choices,
              isMultiSelect: widget.question.isMultiSelect,
              variant: EditorStyleVariant.questionCard,
              onMultiSelectChanged: (value) => setState(() {
                widget.question.isMultiSelect = value;
                if (!value) {
                  bool found = false;
                  for (final c in widget.question.choices) {
                    if (c.isCorrect && found) c.isCorrect = false;
                    if (c.isCorrect) found = true;
                  }
                }
              }),
              onChoiceCorrectChanged: (index, isCorrect) => setState(() {
                widget.question.choices[index].isCorrect = isCorrect;
              }),
              onChoiceTextChanged: (index, text) => setState(() {
                widget.question.choices[index].text = text;
              }),
              onAddChoice: () => setState(() {
                widget.question.choices.add(ChoiceDraft());
              }),
              onRemoveChoice: (index) => setState(() {
                widget.question.choices.removeAt(index);
              }),
              onStructuralChange: () => setState(() => widget.onChanged()),
            ),
          if (widget.question.type == 'identification')
            QuestionEditorBody(
              questionType: 'identification',
              answerItems: widget.question.acceptableAnswers,
              variant: EditorStyleVariant.questionCard,
              onAnswerChanged: (index, text) => setState(() {
                widget.question.acceptableAnswers[index] = text;
              }),
              onAddAnswer: () => setState(() {
                widget.question.acceptableAnswers.add('');
              }),
              onRemoveAnswer: (index) => setState(() {
                widget.question.acceptableAnswers.removeAt(index);
              }),
              onStructuralChange: () => setState(() => widget.onChanged()),
            ),
          if (widget.question.type == 'enumeration')
            QuestionEditorBody(
              questionType: 'enumeration',
              enumerationItems: widget.question.enumerationItems,
              variant: EditorStyleVariant.questionCard,
              onEnumAnswerChanged: (itemIndex, answerIndex, text) => setState(() {
                widget.question.enumerationItems[itemIndex].answers[answerIndex] = text;
              }),
              onAddEnumItem: () => setState(() {
                widget.question.enumerationItems.add(EnumerationItemDraft());
              }),
              onRemoveEnumItem: (itemIndex) => setState(() {
                widget.question.enumerationItems.removeAt(itemIndex);
              }),
              onAddEnumAnswer: (itemIndex) => setState(() {
                widget.question.enumerationItems[itemIndex].answers.add('');
              }),
              onRemoveEnumAnswer: (itemIndex, answerIndex) => setState(() {
                widget.question.enumerationItems[itemIndex].answers.removeAt(answerIndex);
              }),
              onStructuralChange: () => setState(() => widget.onChanged()),
            ),
          ],
        ),
      ),
    );
  }
}

