import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_editor_body.dart';

/// Editor section for identification-type questions.
///
/// Renders a list of acceptable answer fields (draft strings or
/// [TextEditingController]s) plus an "Add Answer" button.
class IdentificationSectionEditor extends StatelessWidget {
  final List<dynamic> answerItems;
  final bool isLoading;
  final EditorStyleVariant variant;
  final Function(int, String)? onAnswerChanged;
  final VoidCallback? onAddAnswer;
  final Function(int)? onRemoveAnswer;
  final VoidCallback? onStructuralChange;

  const IdentificationSectionEditor({
    super.key,
    required this.answerItems,
    required this.isLoading,
    required this.variant,
    this.onAnswerChanged,
    this.onAddAnswer,
    this.onRemoveAnswer,
    this.onStructuralChange,
  });

  InputDecoration _inputDecoration(String labelText) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.borderLight),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.accentCharcoal, width: 1.5),
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
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDraft = answerItems is List<String>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acceptable Answers',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.foregroundPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        ...answerItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final text = isDraft ? (item as String) : '';
          final controller = !isDraft ? (item as TextEditingController) : null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: isDraft
                      ? TextFormField(
                          initialValue: text,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.foregroundPrimary,
                          ),
                          decoration: _inputDecoration('Answer ${index + 1}'),
                          onChanged: (v) => onAnswerChanged?.call(index, v),
                        )
                      : TextFormField(
                          controller: controller,
                          decoration: _inputDecoration('Answer ${index + 1}'),
                          enabled: !isLoading,
                        ),
                ),
                if (answerItems.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.foregroundSecondary),
                    onPressed: isLoading
                        ? null
                        : () {
                            if (!isDraft && controller != null) controller.dispose();
                            onRemoveAnswer?.call(index);
                            onStructuralChange?.call();
                          },
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: isLoading ? null : onAddAnswer,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accentCharcoal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Answer'),
        ),
      ],
    );
  }
}
