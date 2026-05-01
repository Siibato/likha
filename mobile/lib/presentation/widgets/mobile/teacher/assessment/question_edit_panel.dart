import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_draft.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_type_dropdown.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_editor_body.dart';

/// Inline edit form for a single [QuestionDraft].
///
/// Manages its own working copy of the draft so the parent can cancel without
/// mutating the original. Calls [onSave] with the updated draft on valid submit.
class QuestionEditPanel extends StatefulWidget {
  final QuestionDraft draft;
  final int index;
  final VoidCallback onCancel;
  final void Function(QuestionDraft updated) onSave;

  const QuestionEditPanel({
    super.key,
    required this.draft,
    required this.index,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<QuestionEditPanel> createState() => _QuestionEditPanelState();
}

class _QuestionEditPanelState extends State<QuestionEditPanel> {
  late String _type;
  late int _points;
  late bool _isMultiSelect;
  late List<ChoiceDraft> _choices;
  late List<String> _acceptableAnswers;
  late List<EnumerationItemDraft> _enumerationItems;
  late TextEditingController _questionTextCtrl;
  late TextEditingController _pointsCtrl;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _type = d.type;
    _points = d.points;
    _isMultiSelect = d.isMultiSelect;
    _choices = d.choices.map((c) => ChoiceDraft(text: c.text, isCorrect: c.isCorrect)).toList();
    _acceptableAnswers = List<String>.from(d.acceptableAnswers);
    _enumerationItems = d.enumerationItems
        .map((e) => EnumerationItemDraft(answers: List<String>.from(e.answers)))
        .toList();
    _questionTextCtrl = TextEditingController(text: d.questionText);
    _pointsCtrl = TextEditingController(text: d.points.toString());
  }

  @override
  void dispose() {
    _questionTextCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  void _onTypeChanged(String? newType) {
    if (newType == null || newType == _type) return;
    setState(() {
      _type = newType;
      if (newType == 'multiple_choice') {
        _choices = [ChoiceDraft(), ChoiceDraft()];
        _isMultiSelect = false;
      } else if (newType == 'identification') {
        _acceptableAnswers = [''];
      } else if (newType == 'enumeration') {
        _enumerationItems = [];
      }
      _validationError = null;
    });
  }

  void _save() {
    final questionText = _questionTextCtrl.text.trim();
    if (questionText.isEmpty) {
      setState(() => _validationError = 'Question text is required');
      return;
    }
    if (_type == 'multiple_choice') {
      if (_choices.length < 2) {
        setState(() => _validationError = 'At least 2 choices are required');
        return;
      }
      if (!_choices.any((c) => c.isCorrect)) {
        setState(() => _validationError = 'At least one choice must be correct');
        return;
      }
    } else if (_type == 'identification') {
      if (_acceptableAnswers.where((a) => a.trim().isNotEmpty).isEmpty) {
        setState(() => _validationError = 'At least one acceptable answer is required');
        return;
      }
    } else if (_type == 'enumeration') {
      if (_enumerationItems.isEmpty) {
        setState(() => _validationError = 'At least one enumeration item is required');
        return;
      }
    }
    widget.onSave(QuestionDraft(
      type: _type,
      questionText: questionText,
      points: int.tryParse(_pointsCtrl.text) ?? _points,
      isMultiSelect: _isMultiSelect,
      choices: _choices,
      acceptableAnswers: _acceptableAnswers,
      enumerationItems: _enumerationItems,
    ));
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14, color: AppColors.foregroundTertiary),
      filled: true,
      fillColor: AppColors.backgroundSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accentCharcoal, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: widget.onCancel,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.foregroundSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCharcoal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
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
                    style: const TextStyle(color: AppColors.semanticError, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        QuestionTypeDropdown(value: _type, onChanged: _onTypeChanged),
        const SizedBox(height: 12),
        TextFormField(
          controller: _questionTextCtrl,
          maxLines: 3,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.foregroundPrimary,
          ),
          decoration: _fieldDecoration('Question Text'),
          onChanged: (_) {
            if (_validationError != null) setState(() => _validationError = null);
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _pointsCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.foregroundPrimary,
          ),
          decoration: _fieldDecoration('Points'),
        ),
        const SizedBox(height: 16),
        if (_type == 'multiple_choice')
          QuestionEditorBody(
            questionType: 'multiple_choice',
            choices: _choices,
            isMultiSelect: _isMultiSelect,
            variant: EditorStyleVariant.questionCard,
            onMultiSelectChanged: (value) => setState(() {
              _isMultiSelect = value;
              if (!value) {
                bool found = false;
                for (final c in _choices) {
                  if (c.isCorrect && found) c.isCorrect = false;
                  if (c.isCorrect) found = true;
                }
              }
            }),
            onChoiceCorrectChanged: (i, isCorrect) =>
                setState(() => _choices[i].isCorrect = isCorrect),
            onChoiceTextChanged: (i, text) => setState(() => _choices[i].text = text),
            onAddChoice: () => setState(() => _choices.add(ChoiceDraft())),
            onRemoveChoice: (i) => setState(() => _choices.removeAt(i)),
            onStructuralChange: () => setState(() {}),
          ),
        if (_type == 'identification')
          QuestionEditorBody(
            questionType: 'identification',
            answerItems: _acceptableAnswers,
            variant: EditorStyleVariant.questionCard,
            onAnswerChanged: (i, text) => setState(() => _acceptableAnswers[i] = text),
            onAddAnswer: () => setState(() => _acceptableAnswers.add('')),
            onRemoveAnswer: (i) => setState(() => _acceptableAnswers.removeAt(i)),
            onStructuralChange: () => setState(() {}),
          ),
        if (_type == 'enumeration')
          QuestionEditorBody(
            questionType: 'enumeration',
            enumerationItems: _enumerationItems,
            variant: EditorStyleVariant.questionCard,
            onEnumAnswerChanged: (itemIndex, answerIndex, text) =>
                setState(() => _enumerationItems[itemIndex].answers[answerIndex] = text),
            onAddEnumItem: () => setState(() => _enumerationItems.add(EnumerationItemDraft())),
            onRemoveEnumItem: (i) => setState(() => _enumerationItems.removeAt(i)),
            onAddEnumAnswer: (i) => setState(() => _enumerationItems[i].answers.add('')),
            onRemoveEnumAnswer: (i, j) =>
                setState(() => _enumerationItems[i].answers.removeAt(j)),
            onStructuralChange: () => setState(() {}),
          ),
        if (_type == 'essay')
          const QuestionEditorBody(
            questionType: 'essay',
            variant: EditorStyleVariant.questionCard,
          ),
      ],
    );
  }
}
