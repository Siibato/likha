import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_question_type_editors.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_draft.dart';

/// Inline edit form for a question in the desktop assessment builder.
///
/// Owns a working copy of the question; calls [onSave] with the updated
/// [QuestionDraft] when the user confirms, or [onCancel] to discard.
class AssessmentQuestionEditFormDesktop extends StatefulWidget {
  final QuestionDraft draft;
  final void Function(QuestionDraft updated) onSave;
  final VoidCallback onCancel;

  const AssessmentQuestionEditFormDesktop({
    super.key,
    required this.draft,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<AssessmentQuestionEditFormDesktop> createState() =>
      _AssessmentQuestionEditFormDesktopState();
}

class _AssessmentQuestionEditFormDesktopState
    extends State<AssessmentQuestionEditFormDesktop> {
  late String _type;
  late TextEditingController _textCtrl;
  late TextEditingController _pointsCtrl;
  late bool _multiSelect;
  late List<ChoiceDraft> _choices;
  late List<String> _answers;
  late List<EnumerationItemDraft> _enumItems;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final q = widget.draft;
    _type = q.type;
    _textCtrl = TextEditingController(text: q.questionText);
    _pointsCtrl = TextEditingController(text: q.points.toString());
    _multiSelect = q.isMultiSelect;
    _choices = q.choices
        .map((c) => ChoiceDraft(text: c.text, isCorrect: c.isCorrect))
        .toList();
    _answers = List<String>.from(q.acceptableAnswers);
    _enumItems = q.enumerationItems
        .map((e) => EnumerationItemDraft(answers: List<String>.from(e.answers)))
        .toList();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  void _onTypeChanged(String? newType) {
    if (newType == null) return;
    setState(() {
      _type = newType;
      _choices = [ChoiceDraft(), ChoiceDraft()];
      _answers = [''];
      _enumItems = [EnumerationItemDraft()];
      _multiSelect = false;
      _validationError = null;
    });
  }

  void _save() {
    if (_textCtrl.text.trim().isEmpty) {
      setState(() => _validationError = 'Question text is required');
      return;
    }

    if (_type == 'multiple_choice') {
      final nonEmpty =
          _choices.where((c) => c.text.trim().isNotEmpty).toList();
      if (nonEmpty.length < 2) {
        setState(() =>
            _validationError = 'At least 2 choices are required');
        return;
      }
      if (!nonEmpty.any((c) => c.isCorrect)) {
        setState(
            () => _validationError = 'Mark at least one correct choice');
        return;
      }
    } else if (_type == 'identification') {
      final nonEmpty =
          _answers.where((a) => a.trim().isNotEmpty).toList();
      if (nonEmpty.isEmpty) {
        setState(() =>
            _validationError = 'At least one acceptable answer is required');
        return;
      }
    } else if (_type == 'enumeration') {
      if (_enumItems.isEmpty) {
        setState(() =>
            _validationError = 'At least one enumeration item is required');
        return;
      }
      for (int i = 0; i < _enumItems.length; i++) {
        final nonEmpty =
            _enumItems[i].answers.where((a) => a.trim().isNotEmpty).toList();
        if (nonEmpty.isEmpty) {
          setState(() => _validationError =
              'Item ${i + 1} needs at least one acceptable answer');
          return;
        }
      }
    }

    final points = int.tryParse(_pointsCtrl.text.trim()) ?? 1;

    late List<ChoiceDraft> savedChoices;
    late List<String> savedAnswers;
    late List<EnumerationItemDraft> savedEnumItems;

    if (_type == 'multiple_choice') {
      savedChoices = _choices
          .where((c) => c.text.trim().isNotEmpty)
          .map((c) => ChoiceDraft(text: c.text.trim(), isCorrect: c.isCorrect))
          .toList();
      savedAnswers = [''];
      savedEnumItems = [];
    } else if (_type == 'identification') {
      savedChoices = [ChoiceDraft(), ChoiceDraft()];
      savedAnswers = _answers
          .where((a) => a.trim().isNotEmpty)
          .map((a) => a.trim())
          .toList();
      savedEnumItems = [];
    } else if (_type == 'enumeration') {
      savedChoices = [ChoiceDraft(), ChoiceDraft()];
      savedAnswers = [''];
      savedEnumItems = _enumItems;
    } else {
      savedChoices = [ChoiceDraft(), ChoiceDraft()];
      savedAnswers = [''];
      savedEnumItems = [];
    }

    widget.onSave(
      QuestionDraft(
        type: _type,
        questionText: _textCtrl.text.trim(),
        points: points,
        isMultiSelect: _multiSelect,
        choices: savedChoices,
        acceptableAnswers: savedAnswers,
        enumerationItems: savedEnumItems,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.accentCharcoal,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Edit Question',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentCharcoal,
                ),
              ),
              const Spacer(),
              if (_validationError != null)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.semanticErrorBackground,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.semanticError,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _validationError!,
                        style: const TextStyle(
                          color: AppColors.semanticError,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              TextButton(
                onPressed: widget.onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.foregroundSecondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCharcoal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: assessmentInputDecoration('Question Type'),
            items: const [
              DropdownMenuItem(
                value: 'multiple_choice',
                child: Text('Multiple Choice'),
              ),
              DropdownMenuItem(
                value: 'identification',
                child: Text('Identification'),
              ),
              DropdownMenuItem(
                value: 'enumeration',
                child: Text('Enumeration'),
              ),
              DropdownMenuItem(value: 'essay', child: Text('Essay')),
            ],
            onChanged: _onTypeChanged,
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _textCtrl,
            decoration: assessmentInputDecoration('Question Text'),
            maxLines: 3,
            onChanged: (_) {
              if (_validationError != null) {
                setState(() => _validationError = null);
              }
            },
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _pointsCtrl,
            decoration: assessmentInputDecoration('Points'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),

          if (_type == 'multiple_choice') ...[
            _SwitchTile(
              title: 'Multi-select',
              subtitle: 'Allow selecting multiple correct answers',
              value: _multiSelect,
              onChanged: (v) {
                setState(() {
                  _multiSelect = v;
                  if (!v) {
                    bool found = false;
                    for (final c in _choices) {
                      if (c.isCorrect) {
                        if (found) {
                          c.isCorrect = false;
                        }
                        found = true;
                      }
                    }
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            QuestionChoicesEditor(
              key: ValueKey('edit_choices_$_type'),
              initial: _choices,
              isMultiSelect: _multiSelect,
              onChanged: (updated) => setState(() => _choices = updated),
            ),
          ],
          if (_type == 'identification')
            QuestionAnswersEditor(
              key: ValueKey('edit_answers_$_type'),
              initial: _answers,
              onChanged: (updated) => setState(() => _answers = updated),
            ),
          if (_type == 'enumeration')
            QuestionEnumerationEditor(
              key: ValueKey('edit_enum_$_type'),
              initial: _enumItems,
              onChanged: (updated) => setState(() => _enumItems = updated),
            ),
          if (_type == 'essay')
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Essay questions are graded manually. No additional fields needed.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.foregroundTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.accentCharcoal,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.foregroundTertiary,
          ),
        ),
        value: value,
        activeThumbColor: AppColors.accentCharcoal,
        onChanged: onChanged,
      ),
    );
  }
}
