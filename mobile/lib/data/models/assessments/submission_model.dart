import 'package:likha/domain/assessments/entities/submission.dart';

/// Server sends NaiveDateTime (UTC without Z suffix).
/// Dart's DateTime.parse treats bare strings as local time, causing
/// wrong elapsed-time calculations. Appending 'Z' forces UTC parsing.
DateTime _parseUtc(String s) =>
    DateTime.parse(s.endsWith('Z') ? s : '${s}Z');

class SubmissionSummaryModel extends SubmissionSummary {
  const SubmissionSummaryModel({
    required super.id,
    required super.studentId,
    required super.studentName,
    required super.studentUsername,
    required super.startedAt,
    super.submittedAt,
    required super.autoScore,
    required super.finalScore,
    required super.isSubmitted,
  });

  factory SubmissionSummaryModel.fromJson(Map<String, dynamic> json) {
    return SubmissionSummaryModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      studentUsername: json['student_username'] as String,
      startedAt: _parseUtc(json['started_at'] as String),
      submittedAt: json['submitted_at'] != null
          ? _parseUtc(json['submitted_at'] as String)
          : null,
      autoScore: (json['auto_score'] as num).toDouble(),
      finalScore: (json['final_score'] as num).toDouble(),
      isSubmitted: json['is_submitted'] as bool,
    );
  }

  /// Maps SQLite row to model (used by local datasource)
  factory SubmissionSummaryModel.fromMap(Map<String, dynamic> map) {
    return SubmissionSummaryModel(
      id: map['id'] as String,
      studentId: map['student_id'] as String? ?? '',
      studentName: map['student_name'] as String? ?? '',
      studentUsername: map['student_username'] as String? ?? '',
      startedAt: DateTime.parse(map['started_at'] as String),
      submittedAt: map['submitted_at'] != null
          ? DateTime.parse(map['submitted_at'] as String)
          : null,
      autoScore: (map['auto_score'] as int?)?.toDouble() ?? 0.0,
      finalScore: (map['final_score'] as int?)?.toDouble() ?? 0.0,
      isSubmitted: (map['is_submitted'] as int?) == 1,
    );
  }
}

class SubmissionDetailModel extends SubmissionDetail {
  const SubmissionDetailModel({
    required super.id,
    required super.assessmentId,
    required super.studentId,
    required super.studentName,
    required super.startedAt,
    super.submittedAt,
    required super.autoScore,
    required super.finalScore,
    required super.isSubmitted,
    required super.answers,
  });

  factory SubmissionDetailModel.fromJson(Map<String, dynamic> json) {
    return SubmissionDetailModel(
      id: json['id'] as String,
      assessmentId: json['assessment_id'] as String,
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      startedAt: _parseUtc(json['started_at'] as String),
      submittedAt: json['submitted_at'] != null
          ? _parseUtc(json['submitted_at'] as String)
          : null,
      autoScore: (json['auto_score'] as num).toDouble(),
      finalScore: (json['final_score'] as num).toDouble(),
      isSubmitted: json['is_submitted'] as bool,
      answers: (json['answers'] as List<dynamic>)
          .map((e) =>
              SubmissionAnswerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SubmissionAnswerModel extends SubmissionAnswer {
  const SubmissionAnswerModel({
    required super.id,
    required super.questionId,
    required super.questionText,
    required super.questionType,
    required super.points,
    super.answerText,
    super.selectedChoices,
    super.enumerationAnswers,
    super.isAutoCorrect,
    super.isOverrideCorrect,
    required super.pointsAwarded,
  });

  factory SubmissionAnswerModel.fromJson(Map<String, dynamic> json) {
    return SubmissionAnswerModel(
      id: json['id'] as String,
      questionId: json['question_id'] as String,
      questionText: json['question_text'] as String,
      questionType: json['question_type'] as String,
      points: json['points'] as int,
      answerText: json['answer_text'] as String?,
      selectedChoices: (json['selected_choices'] as List<dynamic>?)
          ?.map((e) =>
              SelectedChoiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      enumerationAnswers: (json['enumeration_answers'] as List<dynamic>?)
          ?.map((e) =>
              EnumerationAnswerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isAutoCorrect: json['is_auto_correct'] as bool?,
      isOverrideCorrect: json['is_override_correct'] as bool?,
      pointsAwarded: (json['points_awarded'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'question_id': questionId,
    'question_text': questionText,
    'question_type': questionType,
    'points': points,
    'answer_text': answerText,
    'selected_choices': selectedChoices
        ?.map((c) => (c as SelectedChoiceModel).toJson())
        .toList(),
    'enumeration_answers': enumerationAnswers
        ?.map((e) => (e as EnumerationAnswerModel).toJson())
        .toList(),
    'is_auto_correct': isAutoCorrect,
    'is_override_correct': isOverrideCorrect,
    'points_awarded': pointsAwarded,
  };
}

class SelectedChoiceModel extends SelectedChoice {
  const SelectedChoiceModel({
    required super.choiceId,
    required super.choiceText,
    required super.isCorrect,
  });

  factory SelectedChoiceModel.fromJson(Map<String, dynamic> json) {
    return SelectedChoiceModel(
      choiceId: json['choice_id'] as String,
      choiceText: json['choice_text'] as String,
      isCorrect: json['is_correct'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'choice_id': choiceId,
    'choice_text': choiceText,
    'is_correct': isCorrect,
  };
}

class EnumerationAnswerModel extends EnumerationAnswer {
  const EnumerationAnswerModel({
    required super.id,
    required super.answerText,
    super.matchedItemId,
    super.isAutoCorrect,
    super.isOverrideCorrect,
  });

  factory EnumerationAnswerModel.fromJson(Map<String, dynamic> json) {
    return EnumerationAnswerModel(
      id: json['id'] as String,
      answerText: json['answer_text'] as String,
      matchedItemId: json['matched_item_id'] as String?,
      isAutoCorrect: json['is_auto_correct'] as bool?,
      isOverrideCorrect: json['is_override_correct'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'answer_text': answerText,
    'matched_item_id': matchedItemId,
    'is_auto_correct': isAutoCorrect,
    'is_override_correct': isOverrideCorrect,
  };
}

class StartSubmissionResultModel extends StartSubmissionResult {
  const StartSubmissionResultModel({
    required super.submissionId,
    required super.startedAt,
    required super.questions,
  });

  factory StartSubmissionResultModel.fromJson(Map<String, dynamic> json) {
    return StartSubmissionResultModel(
      submissionId: json['submission_id'] as String,
      startedAt: _parseUtc(json['started_at'] as String),
      questions: json['questions'] as List<dynamic>,
    );
  }
}

class StudentResultModel extends StudentResult {
  const StudentResultModel({
    required super.submissionId,
    required super.autoScore,
    required super.finalScore,
    required super.totalPoints,
    super.submittedAt,
    required super.answers,
  });

  factory StudentResultModel.fromJson(Map<String, dynamic> json) {
    return StudentResultModel(
      submissionId: json['submission_id'] as String,
      autoScore: (json['auto_score'] as num).toDouble(),
      finalScore: (json['final_score'] as num).toDouble(),
      totalPoints: json['total_points'] as int,
      submittedAt: json['submitted_at'] != null
          ? _parseUtc(json['submitted_at'] as String)
          : null,
      answers: (json['answers'] as List<dynamic>)
          .map((e) => StudentAnswerResultModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StudentAnswerResultModel extends StudentAnswerResult {
  const StudentAnswerResultModel({
    required super.questionId,
    required super.questionText,
    required super.questionType,
    required super.points,
    required super.pointsAwarded,
    super.isCorrect,
    super.answerText,
    super.selectedChoices,
    super.enumerationAnswers,
    super.correctAnswers,
  });

  factory StudentAnswerResultModel.fromJson(Map<String, dynamic> json) {
    return StudentAnswerResultModel(
      questionId: json['question_id'] as String,
      questionText: json['question_text'] as String,
      questionType: json['question_type'] as String,
      points: json['points'] as int,
      pointsAwarded: (json['points_awarded'] as num).toDouble(),
      isCorrect: json['is_correct'] as bool?,
      answerText: json['answer_text'] as String?,
      selectedChoices: (json['selected_choices'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      enumerationAnswers: (json['enumeration_answers'] as List<dynamic>?)
          ?.map((e) => StudentEnumAnswerResultModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
      correctAnswers: (json['correct_answers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}

class StudentEnumAnswerResultModel extends StudentEnumAnswerResult {
  const StudentEnumAnswerResultModel({
    required super.answerText,
    super.isCorrect,
  });

  factory StudentEnumAnswerResultModel.fromJson(Map<String, dynamic> json) {
    return StudentEnumAnswerResultModel(
      answerText: json['answer_text'] as String,
      isCorrect: json['is_correct'] as bool?,
    );
  }
}
