import 'package:equatable/equatable.dart';

class Question extends Equatable {
  final String id;
  final String assessmentId;
  final String questionType;
  final String questionText;
  final int points;
  final int orderIndex;
  final bool isMultiSelect;
  final List<Choice>? choices;
  final List<CorrectAnswer>? correctAnswers;
  final List<EnumerationItem>? enumerationItems;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? cachedAt;
  final bool needsSync;

  const Question({
    required this.id,
    required this.assessmentId,
    required this.questionType,
    required this.questionText,
    required this.points,
    required this.orderIndex,
    required this.isMultiSelect,
    this.choices,
    this.correctAnswers,
    this.enumerationItems,
    this.createdAt,
    this.updatedAt,
    this.cachedAt,
    this.needsSync = false,
  });

  @override
  List<Object?> get props => [id, assessmentId, questionType, questionText, points, orderIndex, createdAt, updatedAt, needsSync, cachedAt];
}

class Choice extends Equatable {
  final String id;
  final String choiceText;
  final bool isCorrect;
  final int orderIndex;

  const Choice({
    required this.id,
    required this.choiceText,
    required this.isCorrect,
    required this.orderIndex,
  });

  @override
  List<Object?> get props => [id, choiceText, isCorrect, orderIndex];
}

class CorrectAnswer extends Equatable {
  final String id;
  final String answerText;

  const CorrectAnswer({required this.id, required this.answerText});

  @override
  List<Object?> get props => [id, answerText];
}

class EnumerationItem extends Equatable {
  final String id;
  final int orderIndex;
  final List<EnumerationItemAnswer> acceptableAnswers;

  const EnumerationItem({
    required this.id,
    required this.orderIndex,
    required this.acceptableAnswers,
  });

  @override
  List<Object?> get props => [id, orderIndex, acceptableAnswers];
}

class EnumerationItemAnswer extends Equatable {
  final String id;
  final String answerText;

  const EnumerationItemAnswer({required this.id, required this.answerText});

  @override
  List<Object?> get props => [id, answerText];
}

class StudentQuestion extends Equatable {
  final String id;
  final String questionType;
  final String questionText;
  final int points;
  final int orderIndex;
  final bool isMultiSelect;
  final List<StudentChoice>? choices;
  final int? enumerationCount;

  const StudentQuestion({
    required this.id,
    required this.questionType,
    required this.questionText,
    required this.points,
    required this.orderIndex,
    required this.isMultiSelect,
    this.choices,
    this.enumerationCount,
  });

  @override
  List<Object?> get props => [id, questionType, questionText, points];
}

class StudentChoice extends Equatable {
  final String id;
  final String choiceText;
  final int orderIndex;

  const StudentChoice({
    required this.id,
    required this.choiceText,
    required this.orderIndex,
  });

  @override
  List<Object?> get props => [id, choiceText, orderIndex];
}
