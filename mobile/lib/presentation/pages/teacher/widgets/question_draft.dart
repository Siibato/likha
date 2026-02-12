class ChoiceDraft {
  String text;
  bool isCorrect;

  ChoiceDraft({this.text = '', this.isCorrect = false});
}

class EnumerationItemDraft {
  List<String> answers;

  EnumerationItemDraft({List<String>? answers}) : answers = answers ?? [''];
}

class QuestionDraft {
  String type;
  String questionText;
  int points;
  bool isMultiSelect;
  List<ChoiceDraft> choices;
  List<String> acceptableAnswers;
  List<EnumerationItemDraft> enumerationItems;

  QuestionDraft({
    this.type = 'multiple_choice',
    this.questionText = '',
    this.points = 1,
    this.isMultiSelect = false,
    List<ChoiceDraft>? choices,
    List<String>? acceptableAnswers,
    List<EnumerationItemDraft>? enumerationItems,
  })  : choices = choices ?? [ChoiceDraft(), ChoiceDraft()],
        acceptableAnswers = acceptableAnswers ?? [''],
        enumerationItems = enumerationItems ?? [];
}