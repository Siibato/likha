import 'package:likha/domain/assessments/entities/question.dart';

class QuestionModel extends Question {
  final DateTime? deletedAt;

  const QuestionModel({
    required super.id,
    required super.assessmentId,
    required super.questionType,
    required super.questionText,
    required super.points,
    required super.orderIndex,
    required super.isMultiSelect,
    super.choices,
    super.correctAnswers,
    super.enumerationItems,
    super.createdAt,
    super.updatedAt,
    super.cachedAt,
    super.needsSync = false,
    this.deletedAt,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      assessmentId: json['assessment_id'] as String? ?? '',
      questionType: json['question_type'] as String,
      questionText: json['question_text'] as String,
      points: json['points'] as int,
      orderIndex: json['order_index'] as int,
      isMultiSelect: _parseBool(json['is_multi_select']) ?? false,
      choices: (json['choices'] as List<dynamic>?)
          ?.map((e) => ChoiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      correctAnswers: (json['correct_answers'] as List<dynamic>?)
          ?.map((e) => CorrectAnswerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      enumerationItems: (json['enumeration_items'] as List<dynamic>?)
          ?.map(
              (e) => EnumerationItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'] as String,
      assessmentId: map['assessment_id'] as String,
      questionType: map['question_type'] as String,
      questionText: map['question_text'] as String,
      points: map['points'] as int,
      orderIndex: map['order_index'] as int,
      isMultiSelect: (map['is_multi_select'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
      cachedAt: map['cached_at'] != null
          ? DateTime.parse(map['cached_at'] as String)
          : null,
      needsSync: (map['needs_sync'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assessment_id': assessmentId,
      'question_type': questionType,
      'question_text': questionText,
      'points': points,
      'order_index': orderIndex,
      'is_multi_select': isMultiSelect ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'cached_at': cachedAt?.toIso8601String(),
      'needs_sync': needsSync ? 1 : 0,
    };
  }

  static bool? _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return null;
  }
}

class ChoiceModel extends Choice {
  const ChoiceModel({
    required super.id,
    required super.choiceText,
    required super.isCorrect,
    required super.orderIndex,
  });

  factory ChoiceModel.fromJson(Map<String, dynamic> json) {
    return ChoiceModel(
      id: json['id'] as String,
      choiceText: json['choice_text'] as String,
      isCorrect: _parseBool(json['is_correct']) ?? false,
      orderIndex: json['order_index'] as int,
    );
  }

  static bool? _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return null;
  }
}

class CorrectAnswerModel extends CorrectAnswer {
  const CorrectAnswerModel({required super.id, required super.answerText});

  factory CorrectAnswerModel.fromJson(Map<String, dynamic> json) {
    return CorrectAnswerModel(
      id: json['id'] as String,
      answerText: json['answer_text'] as String,
    );
  }
}

class EnumerationItemModel extends EnumerationItem {
  const EnumerationItemModel({
    required super.id,
    required super.orderIndex,
    required super.acceptableAnswers,
  });

  factory EnumerationItemModel.fromJson(Map<String, dynamic> json) {
    return EnumerationItemModel(
      id: json['id'] as String,
      orderIndex: json['order_index'] as int,
      acceptableAnswers: (json['acceptable_answers'] as List<dynamic>?)
              ?.map((e) => EnumerationItemAnswerModel.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class EnumerationItemAnswerModel extends EnumerationItemAnswer {
  const EnumerationItemAnswerModel(
      {required super.id, required super.answerText});

  factory EnumerationItemAnswerModel.fromJson(Map<String, dynamic> json) {
    return EnumerationItemAnswerModel(
      id: json['id'] as String,
      answerText: json['answer_text'] as String,
    );
  }
}

class StudentQuestionModel extends StudentQuestion {
  const StudentQuestionModel({
    required super.id,
    required super.questionType,
    required super.questionText,
    required super.points,
    required super.orderIndex,
    required super.isMultiSelect,
    super.choices,
    super.enumerationCount,
  });

  factory StudentQuestionModel.fromJson(Map<String, dynamic> json) {
    return StudentQuestionModel(
      id: json['id'] as String,
      questionType: json['question_type'] as String,
      questionText: json['question_text'] as String,
      points: json['points'] as int,
      orderIndex: json['order_index'] as int,
      isMultiSelect: json['is_multi_select'] as bool? ?? false,
      choices: (json['choices'] as List<dynamic>?)
          ?.map(
              (e) => StudentChoiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      enumerationCount: json['enumeration_count'] as int?,
    );
  }
}

class StudentChoiceModel extends StudentChoice {
  const StudentChoiceModel({
    required super.id,
    required super.choiceText,
    required super.orderIndex,
  });

  factory StudentChoiceModel.fromJson(Map<String, dynamic> json) {
    return StudentChoiceModel(
      id: json['id'] as String,
      choiceText: json['choice_text'] as String,
      orderIndex: json['order_index'] as int,
    );
  }
}
