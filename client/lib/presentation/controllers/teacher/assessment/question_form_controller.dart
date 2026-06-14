import 'package:flutter/material.dart';
import 'package:likha/domain/assessments/entities/question.dart';

// Data classes for editor state (replaces file-local _ChoiceEdit, _EnumerationItemEdit)

class ChoiceEntry {
  final TextEditingController controller;
  bool isCorrect;
  final String? id;

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
  final String? id;

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

/// Controller for both add-question and edit-question flows.
///
/// Owns all mutable form state, validation, and payload building.
/// Pages consume this via [ListenableBuilder].
class QuestionFormController extends ChangeNotifier {
  final TextEditingController questionTextController;
  final TextEditingController pointsController;

  String questionType;
  bool isMultiSelect;
  String? selectedCompetencyId;
  String? selectedCognitiveLevel;
  String? formError;

  final List<ChoiceEntry> choices;
  final List<TextEditingController> acceptableAnswerControllers;
  final List<EnumerationItemEntry> enumerationItems;

  QuestionFormController({
    String? initialQuestionType,
    String? initialQuestionText,
    String? initialPoints,
    bool? initialIsMultiSelect,
    String? initialCompetencyId,
    String? initialCognitiveLevel,
    List<ChoiceEntry>? initialChoices,
    List<TextEditingController>? initialAnswers,
    List<EnumerationItemEntry>? initialEnumerationItems,
  })  : questionTextController =
            TextEditingController(text: initialQuestionText ?? ''),
        pointsController = TextEditingController(text: initialPoints ?? '1'),
        questionType = initialQuestionType ?? 'multiple_choice',
        isMultiSelect = initialIsMultiSelect ?? false,
        selectedCompetencyId = initialCompetencyId,
        selectedCognitiveLevel = initialCognitiveLevel,
        choices = initialChoices ?? [ChoiceEntry(), ChoiceEntry()],
        acceptableAnswerControllers =
            initialAnswers ?? [TextEditingController()],
        enumerationItems = initialEnumerationItems ?? [];

  factory QuestionFormController.fromQuestion(Question question) {
    return QuestionFormController(
      initialQuestionType: question.questionType,
      initialQuestionText: question.questionText,
      initialPoints: question.points.toString(),
      initialIsMultiSelect: question.isMultiSelect,
      initialCompetencyId: question.tosCompetencyId,
      initialCognitiveLevel: question.cognitiveLevel,
      initialChoices: question.choices
          ?.map((c) => ChoiceEntry(
                id: c.id,
                controller: TextEditingController(text: c.choiceText),
                isCorrect: c.isCorrect,
              ))
          .toList(),
      initialAnswers: question.correctAnswers
          ?.map((a) => TextEditingController(text: a.answerText))
          .toList(),
      initialEnumerationItems: question.enumerationItems
          ?.map((item) => EnumerationItemEntry(
                id: item.id,
                answerControllers: item.acceptableAnswers
                    .map((a) => TextEditingController(text: a.answerText))
                    .toList(),
              ))
          .toList(),
    );
  }

  @override
  void dispose() {
    questionTextController.dispose();
    pointsController.dispose();
    for (final c in choices) {
      c.dispose();
    }
    for (final c in acceptableAnswerControllers) {
      c.dispose();
    }
    for (final item in enumerationItems) {
      item.dispose();
    }
    super.dispose();
  }

  void setQuestionType(String value) {
    if (value != questionType) {
      questionType = value;
      notifyListeners();
    }
  }

  void setCompetencyId(String? value) {
    selectedCompetencyId = value;
    notifyListeners();
  }

  void setCognitiveLevel(String? value) {
    selectedCognitiveLevel = value;
    notifyListeners();
  }

  void setIsMultiSelect(bool value) {
    if (value != isMultiSelect) {
      isMultiSelect = value;
      if (!value) {
        bool found = false;
        for (final c in choices) {
          if (c.isCorrect && found) c.isCorrect = false;
          if (c.isCorrect) found = true;
        }
      }
      notifyListeners();
    }
  }

  void addChoice() {
    choices.add(ChoiceEntry());
    notifyListeners();
  }

  void removeChoice(int index) {
    choices[index].dispose();
    choices.removeAt(index);
    notifyListeners();
  }

  void setChoiceCorrect(int index, bool isCorrect) {
    choices[index].isCorrect = isCorrect;
    notifyListeners();
  }

  void setChoiceText(int index, String text) {
    choices[index].controller.text = text;
  }

  void addAnswer() {
    acceptableAnswerControllers.add(TextEditingController());
    notifyListeners();
  }

  void removeAnswer(int index) {
    acceptableAnswerControllers[index].dispose();
    acceptableAnswerControllers.removeAt(index);
    notifyListeners();
  }

  void setAnswerText(int index, String text) {
    acceptableAnswerControllers[index].text = text;
  }

  void addEnumItem() {
    enumerationItems.add(EnumerationItemEntry(
      answerControllers: [TextEditingController()],
    ));
    notifyListeners();
  }

  void removeEnumItem(int index) {
    enumerationItems[index].dispose();
    enumerationItems.removeAt(index);
    notifyListeners();
  }

  void addEnumAnswer(int itemIndex) {
    enumerationItems[itemIndex].answerControllers.add(TextEditingController());
    notifyListeners();
  }

  void removeEnumAnswer(int itemIndex, int answerIndex) {
    enumerationItems[itemIndex].answerControllers[answerIndex].dispose();
    enumerationItems[itemIndex].answerControllers.removeAt(answerIndex);
    notifyListeners();
  }

  void setEnumAnswerText(int itemIndex, int answerIndex, String text) {
    enumerationItems[itemIndex].answerControllers[answerIndex].text = text;
  }

  void notifyStructuralChange() {
    notifyListeners();
  }

  void clearFormError() {
    if (formError != null) {
      formError = null;
      notifyListeners();
    }
  }

  void setFormError(String? error) {
    if (formError != error) {
      formError = error;
      notifyListeners();
    }
  }

  String? validate() {
    final points = int.tryParse(pointsController.text.trim());
    if (points == null || points <= 0) {
      return 'Please enter valid points';
    }

    if (questionType == 'multiple_choice') {
      if (choices.length < 2) {
        return 'At least 2 choices are required';
      }
      if (!choices.any((c) => c.isCorrect)) {
        return 'At least one choice must be correct';
      }
    } else if (questionType == 'identification') {
      final answers = acceptableAnswerControllers
          .where((c) => c.text.trim().isNotEmpty)
          .toList();
      if (answers.isEmpty) {
        return 'At least one acceptable answer is required';
      }
    } else if (questionType == 'enumeration') {
      if (enumerationItems.isEmpty) {
        return 'At least one enumeration item is required';
      }
    }

    return null;
  }

  Map<String, dynamic> buildPayload() {
    final points = int.parse(pointsController.text.trim());
    final data = <String, dynamic>{
      'question_text': questionTextController.text.trim(),
      'points': points,
      if (selectedCompetencyId != null)
        'tos_competency_id': selectedCompetencyId,
      if (selectedCognitiveLevel != null)
        'cognitive_level': selectedCognitiveLevel,
    };

    if (questionType == 'multiple_choice') {
      data['is_multi_select'] = isMultiSelect;
      data['choices'] = choices.asMap().entries.map((entry) {
        final c = entry.value;
        return {
          if (c.id != null) 'id': c.id,
          'choice_text': c.controller.text.trim(),
          'is_correct': c.isCorrect,
          'order_index': entry.key,
        };
      }).toList();
    } else if (questionType == 'identification') {
      data['correct_answers'] = acceptableAnswerControllers
          .where((c) => c.text.trim().isNotEmpty)
          .map((c) => c.text.trim())
          .toList();
    } else if (questionType == 'enumeration') {
      data['enumeration_items'] =
          enumerationItems.asMap().entries.map((entry) {
        final item = entry.value;
        return {
          if (item.id != null) 'id': item.id,
          'order_index': entry.key,
          'acceptable_answers': item.answerControllers
              .where((c) => c.text.trim().isNotEmpty)
              .map((c) => c.text.trim())
              .toList(),
        };
      }).toList();
    }

    return data;
  }

  Map<String, dynamic> buildAddPayload() {
    final base = buildPayload();
    base['question_type'] = questionType;
    base['order_index'] = 0;
    return base;
  }
}
