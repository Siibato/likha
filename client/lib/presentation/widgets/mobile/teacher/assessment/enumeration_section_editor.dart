import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_draft.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_editor_body.dart';

/// Editor section for enumeration-type questions.
///
/// Renders a list of enumeration items, each with their own acceptable-answer
/// variants, and add/remove buttons. Supports both draft and form mode.
class EnumerationSectionEditor extends StatelessWidget {
  final List<dynamic> enumerationItems;
  final bool isLoading;
  final EditorStyleVariant variant;
  final Function(int, int, String)? onEnumAnswerChanged;
  final VoidCallback? onAddEnumItem;
  final Function(int)? onRemoveEnumItem;
  final Function(int, int)? onRemoveEnumAnswer;
  final Function(int)? onAddEnumAnswer;
  final VoidCallback? onStructuralChange;

  const EnumerationSectionEditor({
    super.key,
    required this.enumerationItems,
    required this.isLoading,
    required this.variant,
    this.onEnumAnswerChanged,
    this.onAddEnumItem,
    this.onRemoveEnumItem,
    this.onRemoveEnumAnswer,
    this.onAddEnumAnswer,
    this.onStructuralChange,
  });

  bool get _isDraftMode => enumerationItems is List<EnumerationItemDraft>;

  InputDecoration _inputDecoration(String labelText) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.borderLight),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enumeration Items',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.foregroundPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        ...enumerationItems.asMap().entries.map((itemEntry) {
          final itemIndex = itemEntry.key;
          final item = itemEntry.value;

          final answers = _isDraftMode
              ? (item as EnumerationItemDraft).answers
              : (item as EnumerationItemEntry).answerControllers;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Item ${itemIndex + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.foregroundPrimary,
                      ),
                    ),
                    if (enumerationItems.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        color: AppColors.semanticError,
                        onPressed: isLoading
                            ? null
                            : () {
                                if (!_isDraftMode) {
                                  (item as EnumerationItemEntry).dispose();
                                }
                                onRemoveEnumItem?.call(itemIndex);
                                onStructuralChange?.call();
                              },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Acceptable Answers',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: AppColors.foregroundSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                ...answers.asMap().entries.map((answerEntry) {
                  final answerIndex = answerEntry.key;
                  final answer = answerEntry.value;
                  final text = _isDraftMode ? (answer as String) : '';
                  final controller = !_isDraftMode ? (answer as TextEditingController) : null;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: _isDraftMode
                              ? TextFormField(
                                  initialValue: text,
                                  decoration: _inputDecoration('Variant ${answerIndex + 1}'),
                                  onChanged: (v) => onEnumAnswerChanged?.call(itemIndex, answerIndex, v),
                                )
                              : TextFormField(
                                  controller: controller,
                                  decoration: _inputDecoration('Variant ${answerIndex + 1}'),
                                  enabled: !isLoading,
                                ),
                        ),
                        if (answers.length > 1)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            color: AppColors.foregroundSecondary,
                            onPressed: isLoading
                                ? null
                                : () {
                                    if (!_isDraftMode && controller != null) controller.dispose();
                                    onRemoveEnumAnswer?.call(itemIndex, answerIndex);
                                    onStructuralChange?.call();
                                  },
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: isLoading ? null : () => onAddEnumAnswer?.call(itemIndex),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentCharcoal,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 32),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Variant', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: isLoading ? null : onAddEnumItem,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accentCharcoal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Item'),
        ),
      ],
    );
  }
}
