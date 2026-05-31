import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_draft.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_editor_body.dart';

/// Editor section for multiple-choice questions.
///
/// Shows a multi-select toggle, a list of choice fields with checkboxes,
/// and an "Add Choice" button. Supports both draft mode (string-based) and
/// form mode ([TextEditingController]-based).
class MultipleChoiceSectionEditor extends StatelessWidget {
  final List<dynamic> choices;
  final bool isMultiSelect;
  final bool isLoading;
  final EditorStyleVariant variant;
  final ValueChanged<bool>? onMultiSelectChanged;
  final Function(int, bool)? onChoiceCorrectChanged;
  final Function(int, String)? onChoiceTextChanged;
  final VoidCallback? onAddChoice;
  final Function(int)? onRemoveChoice;
  final VoidCallback? onStructuralChange;

  const MultipleChoiceSectionEditor({
    super.key,
    required this.choices,
    required this.isMultiSelect,
    required this.isLoading,
    required this.variant,
    this.onMultiSelectChanged,
    this.onChoiceCorrectChanged,
    this.onChoiceTextChanged,
    this.onAddChoice,
    this.onRemoveChoice,
    this.onStructuralChange,
  });

  bool get _isDraftMode => choices is List<ChoiceDraft>;

  String _choiceText(dynamic c) {
    if (c is ChoiceDraft) return c.text;
    if (c is ChoiceEntry) return c.controller.text;
    return '';
  }

  bool _choiceCorrect(dynamic c) {
    if (c is ChoiceDraft) return c.isCorrect;
    if (c is ChoiceEntry) return c.isCorrect;
    return false;
  }

  void _setChoiceCorrect(dynamic c, bool value) {
    if (c is ChoiceDraft) c.isCorrect = value;
    if (c is ChoiceEntry) c.isCorrect = value;
  }

  TextEditingController? _choiceController(dynamic c) =>
      c is ChoiceEntry ? c.controller : null;

  InputDecoration _inputDecoration(String labelText) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.borderLight),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.accentCharcoal, width: 1.5),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.semanticError),
    );
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(fontSize: 14, color: AppColors.foregroundTertiary),
      filled: true,
      fillColor: variant == EditorStyleVariant.questionCard
          ? AppColors.backgroundSecondary
          : Colors.white,
      border: border,
      enabledBorder: border,
      focusedBorder: focusedBorder,
      errorBorder: variant == EditorStyleVariant.form ? errorBorder : border,
      focusedErrorBorder: variant == EditorStyleVariant.form ? focusedBorder : focusedBorder,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Multi-select toggle
        Container(
          decoration: BoxDecoration(
            color: variant == EditorStyleVariant.questionCard
                ? AppColors.backgroundSecondary
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: variant == EditorStyleVariant.form
                ? Border.all(color: AppColors.borderLight)
                : null,
          ),
          padding: variant == EditorStyleVariant.form
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          margin: variant == EditorStyleVariant.form
              ? const EdgeInsets.only(bottom: 16)
              : EdgeInsets.zero,
          child: SwitchListTile(
            contentPadding: variant == EditorStyleVariant.form
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            title: const Text(
              'Allow multiple correct answers',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.foregroundPrimary,
              ),
            ),
            value: isMultiSelect,
            activeThumbColor: AppColors.accentCharcoal,
            onChanged: isLoading
                ? null
                : (value) {
                    onMultiSelectChanged?.call(value);
                    if (!value) {
                      bool found = false;
                      for (final c in choices) {
                        final correct = _choiceCorrect(c);
                        if (correct && found) _setChoiceCorrect(c, false);
                        if (correct) found = true;
                      }
                    }
                    onStructuralChange?.call();
                  },
          ),
        ),
        if (variant == EditorStyleVariant.form)
          const SizedBox(height: 16)
        else
          const SizedBox(height: 12),
        const Text(
          'Choices',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.foregroundPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        ...choices.asMap().entries.map((entry) {
          final index = entry.key;
          final choice = entry.value;
          final isCorrect = _choiceCorrect(choice);
          final controller = _choiceController(choice);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Checkbox(
                  value: isCorrect,
                  activeColor: AppColors.accentCharcoal,
                  checkColor: Colors.white,
                  onChanged: isLoading
                      ? null
                      : (value) {
                          if (!isMultiSelect) {
                            for (int i = 0; i < choices.length; i++) {
                              if (i != index) _setChoiceCorrect(choices[i], false);
                            }
                          }
                          onChoiceCorrectChanged?.call(index, value ?? false);
                          onStructuralChange?.call();
                        },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _isDraftMode
                      ? TextFormField(
                          initialValue: _choiceText(choice),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.foregroundPrimary,
                          ),
                          decoration: _inputDecoration('Choice ${index + 1}'),
                          onChanged: (v) => onChoiceTextChanged?.call(index, v),
                        )
                      : TextFormField(
                          controller: controller,
                          decoration: _inputDecoration('Choice ${index + 1}'),
                          enabled: !isLoading,
                        ),
                ),
                if (choices.length > 2)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.foregroundSecondary),
                    onPressed: isLoading
                        ? null
                        : () {
                            if (!_isDraftMode && controller != null) controller.dispose();
                            onRemoveChoice?.call(index);
                            onStructuralChange?.call();
                          },
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: isLoading ? null : onAddChoice,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accentCharcoal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Choice'),
        ),
      ],
    );
  }
}
