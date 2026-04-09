import 'package:flutter/material.dart';
import 'question_draft.dart';

// Data classes for editor state (replaces file-local _ChoiceEdit, _EnumerationItemEdit)

class ChoiceEntry {
  final TextEditingController controller;
  bool isCorrect;
  final String? id; // For edit_question_page tracking

  ChoiceEntry({
    TextEditingController? controller,
    this.isCorrect = false,
    this.id,
  }) : controller = controller ?? TextEditingController();

  void dispose() {
    controller.dispose();
  }
}

class EnumerationItemEntry {
  final List<TextEditingController> answerControllers;
  final String? id; // For edit_question_page tracking

  EnumerationItemEntry({
    List<TextEditingController>? answerControllers,
    this.id,
  }) : answerControllers = answerControllers ?? [];

  void dispose() {
    for (final controller in answerControllers) {
      controller.dispose();
    }
  }
}

enum EditorStyleVariant { questionCard, form }

/// Unified question editor body widget handling Multiple Choice, Identification, and Enumeration questions.
/// Supports both draft mode (QuestionDraft-based) and form mode (TextEditingController-based).
class QuestionEditorBody extends StatelessWidget {
  /// Question type: 'multiple_choice', 'identification', or 'enumeration'
  final String questionType;

  // ============ MULTIPLE CHOICE PARAMETERS ============
  final bool isMultiSelect;
  final List<dynamic>? choices; // List<ChoiceDraft> or List<ChoiceEntry>
  final ValueChanged<bool>? onMultiSelectChanged;
  final Function(int, bool)? onChoiceCorrectChanged;
  final Function(int, String)? onChoiceTextChanged;
  final VoidCallback? onAddChoice;
  final Function(int)? onRemoveChoice;

  // ============ IDENTIFICATION PARAMETERS ============
  final List<dynamic>? answerItems; // List<String> or List<TextEditingController>
  final Function(int, String)? onAnswerChanged;
  final VoidCallback? onAddAnswer;
  final Function(int)? onRemoveAnswer;

  // ============ ENUMERATION PARAMETERS ============
  final List<dynamic>? enumerationItems; // List<EnumerationItemDraft> or List<EnumerationItemEntry>
  final Function(int, int, String)? onEnumAnswerChanged;
  final VoidCallback? onAddEnumItem;
  final Function(int)? onRemoveEnumItem;
  final Function(int, int)? onRemoveEnumAnswer;
  final Function(int)? onAddEnumAnswer;

  // ============ GLOBAL PARAMETERS ============
  final bool isLoading;
  final EditorStyleVariant variant;
  final VoidCallback? onStructuralChange;

  const QuestionEditorBody({
    super.key,
    required this.questionType,
    this.isMultiSelect = false,
    this.choices,
    this.onMultiSelectChanged,
    this.onChoiceCorrectChanged,
    this.onChoiceTextChanged,
    this.onAddChoice,
    this.onRemoveChoice,
    this.answerItems,
    this.onAnswerChanged,
    this.onAddAnswer,
    this.onRemoveAnswer,
    this.enumerationItems,
    this.onEnumAnswerChanged,
    this.onAddEnumItem,
    this.onRemoveEnumItem,
    this.onRemoveEnumAnswer,
    this.onAddEnumAnswer,
    this.isLoading = false,
    this.variant = EditorStyleVariant.form,
    this.onStructuralChange,
  });

  @override
  Widget build(BuildContext context) {
    return switch (questionType) {
      'multiple_choice' => _buildMultipleChoiceSection(),
      'identification' => _buildIdentificationSection(),
      'enumeration' => _buildEnumerationSection(),
      'essay' => _buildEssaySection(),
      _ => const SizedBox.shrink(),
    };
  }

  bool _isDraftMode() => choices is List<ChoiceDraft>;

  // ============ MULTIPLE CHOICE SECTION ============

  Widget _buildMultipleChoiceSection() {
    if (choices == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: variant == EditorStyleVariant.questionCard
                ? const Color(0xFFFAFAFA)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: variant == EditorStyleVariant.form
                ? Border.all(color: const Color(0xFFE0E0E0))
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
                color: Color(0xFF2B2B2B),
              ),
            ),
            value: isMultiSelect,
            activeThumbColor: const Color(0xFF2B2B2B),
            onChanged: isLoading
                ? null
                : (value) {
                    onMultiSelectChanged?.call(value);
                    if (!value) {
                      // Toggle to single-select: keep only first correct
                      bool found = false;
                      for (final c in choices!) {
                        final isCorrect = _getChoiceCorrect(c);
                        if (isCorrect && found) {
                          _setChoiceCorrect(c, false);
                        }
                        if (isCorrect) found = true;
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
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),

        // Choice items
        ...choices!.asMap().entries.map((entry) {
          final index = entry.key;
          final choice = entry.value;
          final text = _getChoiceText(choice);
          final isCorrect = _getChoiceCorrect(choice);
          final controller = _getChoiceController(choice);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Checkbox(
                  value: isCorrect,
                  activeColor: const Color(0xFF2B2B2B),
                  checkColor: Colors.white,
                  onChanged: isLoading
                      ? null
                      : (value) {
                          if (!isMultiSelect) {
                            // Single-select: uncheck all others
                            for (int i = 0; i < choices!.length; i++) {
                              if (i == index) continue;
                              _setChoiceCorrect(choices![i], false);
                            }
                          }
                          onChoiceCorrectChanged?.call(index, value ?? false);
                          onStructuralChange?.call();
                        },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _isDraftMode()
                      ? TextFormField(
                          initialValue: text,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2B2B2B),
                          ),
                          decoration: _buildInputDecoration(
                            labelText: 'Choice ${index + 1}',
                          ),
                          onChanged: (value) {
                            onChoiceTextChanged?.call(index, value);
                          },
                        )
                      : TextFormField(
                          controller: controller,
                          decoration: _buildInputDecoration(
                            labelText: 'Choice ${index + 1}',
                          ),
                          enabled: !isLoading,
                        ),
                ),
                if (choices!.length > 2)
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Color(0xFF666666),
                    ),
                    onPressed: isLoading
                        ? null
                        : () {
                            if (!_isDraftMode() && controller != null) {
                              controller.dispose();
                            }
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
            foregroundColor: const Color(0xFF2B2B2B),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Choice'),
        ),
      ],
    );
  }

  // ============ IDENTIFICATION SECTION ============

  Widget _buildIdentificationSection() {
    if (answerItems == null) return const SizedBox.shrink();

    final isDraft = answerItems is List<String>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acceptable Answers',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),

        // Answer items
        ...answerItems!.asMap().entries.map((entry) {
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
                            color: Color(0xFF2B2B2B),
                          ),
                          decoration: _buildInputDecoration(
                            labelText: 'Answer ${index + 1}',
                          ),
                          onChanged: (value) {
                            onAnswerChanged?.call(index, value);
                          },
                        )
                      : TextFormField(
                          controller: controller,
                          decoration: _buildInputDecoration(
                            labelText: 'Answer ${index + 1}',
                          ),
                          enabled: !isLoading,
                        ),
                ),
                if (answerItems!.length > 1)
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Color(0xFF666666),
                    ),
                    onPressed: isLoading
                        ? null
                        : () {
                            if (!isDraft && controller != null) {
                              controller.dispose();
                            }
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
            foregroundColor: const Color(0xFF2B2B2B),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Answer'),
        ),
      ],
    );
  }

  // ============ ENUMERATION SECTION ============

  Widget _buildEnumerationSection() {
    if (enumerationItems == null) return const SizedBox.shrink();

    final isDraft = enumerationItems is List<EnumerationItemDraft>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enumeration Items',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),

        // Enumeration items
        ...enumerationItems!.asMap().entries.map((itemEntry) {
          final itemIndex = itemEntry.key;
          final item = itemEntry.value;

          final answers = isDraft
              ? (item as EnumerationItemDraft).answers
              : (item as EnumerationItemEntry).answerControllers;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
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
                        color: Color(0xFF2B2B2B),
                      ),
                    ),
                    if (enumerationItems!.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        color: const Color(0xFFEF5350),
                        onPressed: isLoading
                            ? null
                            : () {
                                if (!isDraft) {
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
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 6),

                // Answer variants for this item
                ...answers.asMap().entries.map((answerEntry) {
                  final answerIndex = answerEntry.key;
                  final answer = answerEntry.value;

                  final text = isDraft ? (answer as String) : '';
                  final controller = !isDraft ? (answer as TextEditingController) : null;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: isDraft
                              ? TextFormField(
                                  initialValue: text,
                                  decoration: _buildInputDecoration(
                                    labelText: 'Variant ${answerIndex + 1}',
                                    borderRadius: 8,
                                  ),
                                  onChanged: (value) {
                                    onEnumAnswerChanged?.call(itemIndex, answerIndex, value);
                                  },
                                )
                              : TextFormField(
                                  controller: controller,
                                  decoration: _buildInputDecoration(
                                    labelText: 'Variant ${answerIndex + 1}',
                                    borderRadius: 8,
                                  ),
                                  enabled: !isLoading,
                                ),
                        ),
                        if (answers.length > 1)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            color: const Color(0xFF666666),
                            onPressed: isLoading
                                ? null
                                : () {
                                    if (!isDraft && controller != null) {
                                      controller.dispose();
                                    }
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
                    foregroundColor: const Color(0xFF2B2B2B),
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
            foregroundColor: const Color(0xFF2B2B2B),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Item'),
        ),
      ],
    );
  }

  // ============ ESSAY SECTION ============

  Widget _buildEssaySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF999999)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Essay Question',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF2B2B2B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Students will write a free-form essay response. No answer key required — you will grade this manually after submission.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ HELPER METHODS ============

  InputDecoration _buildInputDecoration({
    required String labelText,
    double borderRadius = 12,
  }) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: const BorderSide(
        color: Color(0xFFE0E0E0),
        width: 1,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: const BorderSide(
        color: Color(0xFF2B2B2B),
        width: 1.5,
      ),
    );

    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: const BorderSide(
        color: Color(0xFFEF5350),
        width: 1,
      ),
    );

    final focusedErrorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: const BorderSide(
        color: Color(0xFFEF5350),
        width: 1.5,
      ),
    );

    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(
        fontSize: 14,
        color: Color(0xFF999999),
      ),
      filled: true,
      fillColor: variant == EditorStyleVariant.questionCard
          ? const Color(0xFFFAFAFA)
          : Colors.white,
      border: baseBorder,
      enabledBorder: baseBorder,
      focusedBorder: focusedBorder,
      errorBorder: variant == EditorStyleVariant.form ? errorBorder : baseBorder,
      focusedErrorBorder: variant == EditorStyleVariant.form ? focusedErrorBorder : focusedBorder,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
    );
  }

  // Helper methods for mode-agnostic choice access

  String _getChoiceText(dynamic choice) {
    if (choice is ChoiceDraft) return choice.text;
    if (choice is ChoiceEntry) return choice.controller.text;
    return '';
  }

  bool _getChoiceCorrect(dynamic choice) {
    if (choice is ChoiceDraft) return choice.isCorrect;
    if (choice is ChoiceEntry) return choice.isCorrect;
    return false;
  }

  void _setChoiceCorrect(dynamic choice, bool value) {
    if (choice is ChoiceDraft) choice.isCorrect = value;
    if (choice is ChoiceEntry) choice.isCorrect = value;
  }

  TextEditingController? _getChoiceController(dynamic choice) {
    if (choice is ChoiceEntry) return choice.controller;
    return null;
  }
}
