import 'package:flutter/material.dart';
import 'enumeration_section_editor.dart';
import 'essay_section_editor.dart';
import 'identification_section_editor.dart';
import 'multiple_choice_section_editor.dart';

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
      'multiple_choice' => choices == null
          ? const SizedBox.shrink()
          : MultipleChoiceSectionEditor(
              choices: choices!,
              isMultiSelect: isMultiSelect,
              isLoading: isLoading,
              variant: variant,
              onMultiSelectChanged: onMultiSelectChanged,
              onChoiceCorrectChanged: onChoiceCorrectChanged,
              onChoiceTextChanged: onChoiceTextChanged,
              onAddChoice: onAddChoice,
              onRemoveChoice: onRemoveChoice,
              onStructuralChange: onStructuralChange,
            ),
      'identification' => answerItems == null
          ? const SizedBox.shrink()
          : IdentificationSectionEditor(
              answerItems: answerItems!,
              isLoading: isLoading,
              variant: variant,
              onAnswerChanged: onAnswerChanged,
              onAddAnswer: onAddAnswer,
              onRemoveAnswer: onRemoveAnswer,
              onStructuralChange: onStructuralChange,
            ),
      'enumeration' => enumerationItems == null
          ? const SizedBox.shrink()
          : EnumerationSectionEditor(
              enumerationItems: enumerationItems!,
              isLoading: isLoading,
              variant: variant,
              onEnumAnswerChanged: onEnumAnswerChanged,
              onAddEnumItem: onAddEnumItem,
              onRemoveEnumItem: onRemoveEnumItem,
              onRemoveEnumAnswer: onRemoveEnumAnswer,
              onAddEnumAnswer: onAddEnumAnswer,
              onStructuralChange: onStructuralChange,
            ),
      'essay' => const EssaySectionEditor(),
      _ => const SizedBox.shrink(),
    };
  }
}
