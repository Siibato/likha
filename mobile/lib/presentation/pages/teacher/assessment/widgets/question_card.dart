import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/presentation/pages/teacher/assessment/widgets/question_draft.dart';
import 'package:likha/presentation/pages/teacher/assessment/widgets/question_type_dropdown.dart';
import 'package:likha/presentation/pages/teacher/assessment/widgets/question_editor_body.dart';
export 'package:likha/presentation/pages/teacher/assessment/widgets/question_editor_body.dart'
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
        return AppColors.accentCharcoal;
      case 'identification':
        return AppColors.foregroundSecondary;
      case 'enumeration':
        return AppColors.foregroundTertiary;
      default:
        return AppColors.foregroundTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      color: AppColors.backgroundTertiary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.borderLight,
                        width: 1,
                      ),
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
                            _QuestionTypeChip(
                              label: _questionTypeLabel(question.questionType),
                              color: _questionTypeColor(question.questionType),
                            ),
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
                                  ? AppColors.semanticSuccess
                                  : AppColors.foregroundLight,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                choice.choiceText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.foregroundSecondary,
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
                        color: AppColors.foregroundTertiary,
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
                      color: AppColors.foregroundSecondary,
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
                            color: AppColors.foregroundTertiary,
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
                              color: AppColors.foregroundSecondary,
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
                        color: AppColors.foregroundTertiary,
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

// Working copy for editing to enable cancel functionality
class _QuestionEditState {
  String type;
  String questionText;
  int points;
  bool isMultiSelect;
  List<ChoiceDraft> choices;
  List<String> acceptableAnswers;
  List<EnumerationItemDraft> enumerationItems;

  _QuestionEditState({
    required this.type,
    required this.questionText,
    required this.points,
    required this.isMultiSelect,
    required this.choices,
    required this.acceptableAnswers,
    required this.enumerationItems,
  });

  factory _QuestionEditState.fromDraft(QuestionDraft draft) {
    return _QuestionEditState(
      type: draft.type,
      questionText: draft.questionText,
      points: draft.points,
      isMultiSelect: draft.isMultiSelect,
      choices: draft.choices.map((c) => ChoiceDraft(text: c.text, isCorrect: c.isCorrect)).toList(),
      acceptableAnswers: List<String>.from(draft.acceptableAnswers),
      enumerationItems: draft.enumerationItems.map((e) => EnumerationItemDraft(answers: List<String>.from(e.answers))).toList(),
    );
  }

  void applyToDraft(QuestionDraft draft) {
    draft.type = type;
    draft.questionText = questionText;
    draft.points = points;
    draft.isMultiSelect = isMultiSelect;
    draft.choices = choices;
    draft.acceptableAnswers = acceptableAnswers;
    draft.enumerationItems = enumerationItems;
  }
}

class _QuestionDraftCardState extends State<QuestionDraftCard> {
  bool _isEditing = false;
  _QuestionEditState? _editState;
  String? _validationError;

  void _enterEditMode() {
    setState(() {
      _isEditing = true;
      _editState = _QuestionEditState.fromDraft(widget.question);
      _validationError = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _editState = null;
      _validationError = null;
    });
  }

  void _saveEdit() {
    if (_editState == null) return;

    // Validation
    if (_editState!.questionText.trim().isEmpty) {
      setState(() => _validationError = 'Question text is required');
      return;
    }

    if (_editState!.type == 'multiple_choice') {
      if (_editState!.choices.length < 2) {
        setState(() => _validationError = 'At least 2 choices are required');
        return;
      }
      if (!_editState!.choices.any((c) => c.isCorrect)) {
        setState(() => _validationError = 'At least one choice must be correct');
        return;
      }
    } else if (_editState!.type == 'identification') {
      final validAnswers = _editState!.acceptableAnswers.where((a) => a.trim().isNotEmpty).toList();
      if (validAnswers.isEmpty) {
        setState(() => _validationError = 'At least one acceptable answer is required');
        return;
      }
    } else if (_editState!.type == 'enumeration') {
      if (_editState!.enumerationItems.isEmpty) {
        setState(() => _validationError = 'At least one enumeration item is required');
        return;
      }
    }

    // Apply changes
    _editState!.applyToDraft(widget.question);
    widget.onChanged();

    setState(() {
      _isEditing = false;
      _editState = null;
      _validationError = null;
    });
  }

  void _onTypeChanged(String? newType) {
    if (newType == null || _editState == null || newType == _editState!.type) return;

    setState(() {
      _editState!.type = newType;
      // Reset answer structures for the new type
      if (newType == 'multiple_choice') {
        _editState!.choices = [ChoiceDraft(), ChoiceDraft()];
        _editState!.isMultiSelect = false;
      } else if (newType == 'identification') {
        _editState!.acceptableAnswers = [''];
      } else if (newType == 'enumeration') {
        _editState!.enumerationItems = [];
      }
      _validationError = null;
    });
  }

  String _getQuestionTypeLabel(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'identification':
        return 'Identification';
      case 'enumeration':
        return 'Enumeration';
      case 'essay':
        return 'Essay';
      default:
        return type;
    }
  }

  Color _getQuestionTypeColor(String type) {
    switch (type) {
      case 'multiple_choice':
        return AppColors.accentCharcoal;
      case 'identification':
        return AppColors.foregroundSecondary;
      case 'enumeration':
        return AppColors.foregroundTertiary;
      case 'essay':
        return AppColors.semanticSuccess;
      default:
        return AppColors.foregroundTertiary;
    }
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(16),
        child: _isEditing ? _buildEditMode() : _buildViewMode(),
      ),
    );
  }

  Widget _buildViewMode() {
    final typeLabel = _getQuestionTypeLabel(widget.question.type);
    final typeColor = _getQuestionTypeColor(widget.question.type);

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
                border: Border.all(
                  color: AppColors.borderLight,
                  width: 1,
                ),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
        // Show answer preview based on type
        if (widget.question.type == 'multiple_choice' &&
            widget.question.choices.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...widget.question.choices.take(4).map(
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
                        ? AppColors.semanticSuccess
                        : AppColors.foregroundLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      choice.text.isEmpty ? '(empty)' : choice.text,
                      style: TextStyle(
                        fontSize: 13,
                        color: choice.isCorrect
                            ? AppColors.foregroundPrimary
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
          if (widget.question.choices.length > 4)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 6),
              child: Text(
                '+${widget.question.choices.length - 4} more choices',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.foregroundTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
        if (widget.question.type == 'identification' &&
            widget.question.acceptableAnswers.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
              'Answers: ${widget.question.acceptableAnswers.where((a) => a.isNotEmpty).join(', ')}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.foregroundSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        if (widget.question.type == 'enumeration' &&
            widget.question.enumerationItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...widget.question.enumerationItems.take(3).toList().asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(left: 44, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key + 1}.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.foregroundTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.value.answers.where((a) => a.isNotEmpty).join(' / '),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.foregroundSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.question.enumerationItems.length > 3)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 6),
              child: Text(
                '+${widget.question.enumerationItems.length - 3} more items',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.foregroundTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
        if (widget.question.type == 'essay') ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Row(
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  size: 16,
                  color: AppColors.semanticSuccess.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Essay question - manually graded',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.foregroundSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
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
              onPressed: _enterEditMode,
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

  Widget _buildEditMode() {
    if (_editState == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Question ${widget.index + 1}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.foregroundDark,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _cancelEdit,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.foregroundSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _saveEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCharcoal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        if (_validationError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.semanticErrorBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.semanticError),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.semanticError, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _validationError!,
                    style: const TextStyle(
                      color: AppColors.semanticError,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        QuestionTypeDropdown(
          value: _editState!.type,
          onChanged: _onTypeChanged,
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: _editState!.questionText,
          maxLines: 3,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.foregroundPrimary,
          ),
          decoration: InputDecoration(
            labelText: 'Question Text',
            labelStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.foregroundTertiary,
            ),
            filled: true,
            fillColor: AppColors.backgroundSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.borderLight,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.borderLight,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accentCharcoal,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: (value) {
            _editState!.questionText = value;
            if (_validationError != null) {
              setState(() => _validationError = null);
            }
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: _editState!.points.toString(),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.foregroundPrimary,
          ),
          decoration: InputDecoration(
            labelText: 'Points',
            labelStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.foregroundTertiary,
            ),
            filled: true,
            fillColor: AppColors.backgroundSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.borderLight,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.borderLight,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accentCharcoal,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: (value) {
            _editState!.points = int.tryParse(value) ?? 1;
          },
        ),
        const SizedBox(height: 16),
        if (_editState!.type == 'multiple_choice')
          QuestionEditorBody(
            questionType: 'multiple_choice',
            choices: _editState!.choices,
            isMultiSelect: _editState!.isMultiSelect,
            variant: EditorStyleVariant.questionCard,
            onMultiSelectChanged: (value) => setState(() {
              _editState!.isMultiSelect = value;
              if (!value) {
                bool found = false;
                for (final c in _editState!.choices) {
                  if (c.isCorrect && found) c.isCorrect = false;
                  if (c.isCorrect) found = true;
                }
              }
            }),
            onChoiceCorrectChanged: (index, isCorrect) => setState(() {
              _editState!.choices[index].isCorrect = isCorrect;
            }),
            onChoiceTextChanged: (index, text) => setState(() {
              _editState!.choices[index].text = text;
            }),
            onAddChoice: () => setState(() {
              _editState!.choices.add(ChoiceDraft());
            }),
            onRemoveChoice: (index) => setState(() {
              _editState!.choices.removeAt(index);
            }),
            onStructuralChange: () => setState(() {}),
          ),
        if (_editState!.type == 'identification')
          QuestionEditorBody(
            questionType: 'identification',
            answerItems: _editState!.acceptableAnswers,
            variant: EditorStyleVariant.questionCard,
            onAnswerChanged: (index, text) => setState(() {
              _editState!.acceptableAnswers[index] = text;
            }),
            onAddAnswer: () => setState(() {
              _editState!.acceptableAnswers.add('');
            }),
            onRemoveAnswer: (index) => setState(() {
              _editState!.acceptableAnswers.removeAt(index);
            }),
            onStructuralChange: () => setState(() {}),
          ),
        if (_editState!.type == 'enumeration')
          QuestionEditorBody(
            questionType: 'enumeration',
            enumerationItems: _editState!.enumerationItems,
            variant: EditorStyleVariant.questionCard,
            onEnumAnswerChanged: (itemIndex, answerIndex, text) => setState(() {
              _editState!.enumerationItems[itemIndex].answers[answerIndex] = text;
            }),
            onAddEnumItem: () => setState(() {
              _editState!.enumerationItems.add(EnumerationItemDraft());
            }),
            onRemoveEnumItem: (itemIndex) => setState(() {
              _editState!.enumerationItems.removeAt(itemIndex);
            }),
            onAddEnumAnswer: (itemIndex) => setState(() {
              _editState!.enumerationItems[itemIndex].answers.add('');
            }),
            onRemoveEnumAnswer: (itemIndex, answerIndex) => setState(() {
              _editState!.enumerationItems[itemIndex].answers.removeAt(answerIndex);
            }),
            onStructuralChange: () => setState(() {}),
          ),
        if (_editState!.type == 'essay')
          const QuestionEditorBody(
            questionType: 'essay',
            variant: EditorStyleVariant.questionCard,
          ),
      ],
    );
  }
}

