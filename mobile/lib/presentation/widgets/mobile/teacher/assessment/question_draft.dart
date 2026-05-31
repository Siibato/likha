class ChoiceDraft {
  String text;
  bool isCorrect;

  ChoiceDraft({this.text = '', this.isCorrect = false});

  Map<String, dynamic> toJson() => {
    'text': text,
    'isCorrect': isCorrect,
  };

  factory ChoiceDraft.fromJson(Map<String, dynamic> json) => ChoiceDraft(
    text: json['text'] as String? ?? '',
    isCorrect: json['isCorrect'] as bool? ?? false,
  );
}

class EnumerationItemDraft {
  List<String> answers;

  EnumerationItemDraft({List<String>? answers}) : answers = answers ?? [''];

  Map<String, dynamic> toJson() => {
    'answers': answers,
  };

  factory EnumerationItemDraft.fromJson(Map<String, dynamic> json) => EnumerationItemDraft(
    answers: List<String>.from(json['answers'] as List? ?? ['']),
  );
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

  Map<String, dynamic> toJson() => {
    'type': type,
    'questionText': questionText,
    'points': points,
    'isMultiSelect': isMultiSelect,
    'choices': choices.map((c) => c.toJson()).toList(),
    'acceptableAnswers': acceptableAnswers,
    'enumerationItems': enumerationItems.map((e) => e.toJson()).toList(),
  };

  factory QuestionDraft.fromJson(Map<String, dynamic> json) => QuestionDraft(
    type: json['type'] as String? ?? 'multiple_choice',
    questionText: json['questionText'] as String? ?? '',
    points: json['points'] as int? ?? 1,
    isMultiSelect: json['isMultiSelect'] as bool? ?? false,
    choices: (json['choices'] as List?)?.map((c) => ChoiceDraft.fromJson(c as Map<String, dynamic>)).toList(),
    acceptableAnswers: List<String>.from(json['acceptableAnswers'] as List? ?? ['']),
    enumerationItems: (json['enumerationItems'] as List?)?.map((e) => EnumerationItemDraft.fromJson(e as Map<String, dynamic>)).toList(),
  );
}