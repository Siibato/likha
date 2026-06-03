import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/snackbar_utils.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_question_type_editors.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_draft.dart';

/// "New Question" inline form for the desktop assessment builder.
///
/// Owns its form state entirely; calls [onConfirm] with a completed
/// [QuestionDraft] or [onCancel] to dismiss without adding.
class AssessmentAddQuestionFormDesktop extends StatefulWidget {
  final void Function(QuestionDraft draft) onConfirm;
  final VoidCallback onCancel;

  const AssessmentAddQuestionFormDesktop({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<AssessmentAddQuestionFormDesktop> createState() =>
      _AssessmentAddQuestionFormDesktopState();
}

class _AssessmentAddQuestionFormDesktopState
    extends State<AssessmentAddQuestionFormDesktop> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'multiple_choice';
  final _textCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController(text: '1');
  bool _multiSelect = false;
  List<ChoiceDraft> _choices = [ChoiceDraft(), ChoiceDraft()];
  List<String> _answers = [''];
  List<EnumerationItemDraft> _enumItems = [EnumerationItemDraft()];

  @override
  void dispose() {
    _textCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  void _onTypeChanged(String? v) {
    if (v == null) return;
    setState(() {
      _type = v;
      _choices = [ChoiceDraft(), ChoiceDraft()];
      _answers = [''];
      _enumItems = [EnumerationItemDraft()];
      _multiSelect = false;
    });
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;

    final points = int.tryParse(_pointsCtrl.text.trim()) ?? 1;

    if (_type == 'multiple_choice') {
      final nonEmpty =
          _choices.where((c) => c.text.trim().isNotEmpty).toList();
      if (nonEmpty.length < 2) {
        context.showErrorSnackBar('At least 2 choices are required');
        return;
      }
      if (!nonEmpty.any((c) => c.isCorrect)) {
        context.showErrorSnackBar('Mark at least one correct choice');
        return;
      }
    } else if (_type == 'identification') {
      final nonEmpty =
          _answers.where((a) => a.trim().isNotEmpty).toList();
      if (nonEmpty.isEmpty) {
        context.showErrorSnackBar(
            'At least one acceptable answer is required');
        return;
      }
    } else if (_type == 'enumeration') {
      if (_enumItems.isEmpty) {
        context.showErrorSnackBar(
            'At least one enumeration item is required');
        return;
      }
      for (int i = 0; i < _enumItems.length; i++) {
        final nonEmpty = _enumItems[i]
            .answers
            .where((a) => a.trim().isNotEmpty)
            .toList();
        if (nonEmpty.isEmpty) {
          context.showErrorSnackBar(
              'Item ${i + 1} needs at least one acceptable answer');
          return;
        }
      }
    }

    widget.onConfirm(
      QuestionDraft(
        type: _type,
        questionText: _textCtrl.text.trim(),
        points: points,
        isMultiSelect: _multiSelect,
        choices: _type == 'multiple_choice'
            ? _choices
                .where((c) => c.text.trim().isNotEmpty)
                .map((c) =>
                    ChoiceDraft(text: c.text.trim(), isCorrect: c.isCorrect))
                .toList()
            : [ChoiceDraft(), ChoiceDraft()],
        acceptableAnswers: _type == 'identification'
            ? _answers
                .where((a) => a.trim().isNotEmpty)
                .map((a) => a.trim())
                .toList()
            : [''],
        enumerationItems:
            _type == 'enumeration' ? _enumItems : [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentCharcoal, width: 1.5),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Question',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.accentCharcoal,
              ),
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
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Question text is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _pointsCtrl,
              decoration: assessmentInputDecoration('Points'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Points required';
                final parsed = int.tryParse(v.trim());
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid point value';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            if (_type == 'multiple_choice') ...[
              _MultiSelectTile(
                value: _multiSelect,
                onChanged: (v) => setState(() => _multiSelect = v),
              ),
              const SizedBox(height: 12),
              QuestionChoicesEditor(
                key: ValueKey('add_choices_$_type'),
                initial: _choices,
                isMultiSelect: _multiSelect,
                onChanged: (updated) => setState(() => _choices = updated),
              ),
            ],
            if (_type == 'identification')
              QuestionAnswersEditor(
                key: ValueKey('add_answers_$_type'),
                initial: _answers,
                onChanged: (updated) => setState(() => _answers = updated),
              ),
            if (_type == 'enumeration')
              QuestionEnumerationEditor(
                key: ValueKey('add_enum_$_type'),
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

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.foregroundSecondary,
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentCharcoal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiSelectTile extends StatelessWidget {
  final bool value;
  final void Function(bool) onChanged;

  const _MultiSelectTile({required this.value, required this.onChanged});

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
        title: const Text(
          'Multi-select',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.accentCharcoal,
          ),
        ),
        subtitle: const Text(
          'Allow selecting multiple correct answers',
          style: TextStyle(fontSize: 13, color: AppColors.foregroundTertiary),
        ),
        value: value,
        activeThumbColor: AppColors.accentCharcoal,
        onChanged: onChanged,
      ),
    );
  }
}
