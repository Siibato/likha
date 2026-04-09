import 'package:likha/domain/assessments/entities/submission.dart';

/// Server sends datetime strings in various formats. Normalize to UTC.
/// Dart's DateTime.parse treats bare strings as local time, causing
/// wrong elapsed-time calculations. This parser ensures UTC interpretation.
/// Handles: "2026-03-10T15:41:38" → "2026-03-10T15:41:38Z"
///          "2026-03-10T15:41:38Z" → "2026-03-10T15:41:38Z"
///          "2026-03-10T15:41:38+00:00Z" → "2026-03-10T15:41:38Z" (malformed, but handled)
DateTime _parseUtc(String s) {
  // Remove trailing Z and any timezone offset info, then re-add Z to force UTC
  String normalized = s.replaceAll(RegExp(r'(Z|[+-]\d{2}:\d{2}(Z)?)$'), '');
  return DateTime.parse('${normalized}Z');
}

class SubmissionSummaryModel extends SubmissionSummary {
  final DateTime? deletedAt;

  const SubmissionSummaryModel({
    required super.id,
    required super.assessmentId,
    required super.studentId,
    required super.studentName,
    required super.studentUsername,
    required super.startedAt,
    super.submittedAt,
    required super.autoScore,
    required super.finalScore,
    required super.totalPoints,
    required super.isSubmitted,
    super.createdAt,
    super.updatedAt,
    super.cachedAt,
    super.needsSync = false,
    this.deletedAt,
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
      autoScore: (json['auto_score'] as num? ?? 0).toDouble(),
      finalScore: (json['final_score'] as num? ?? 0).toDouble(),
      isSubmitted: json['submitted_at'] != null,
      assessmentId: json['assessment_id'] as String? ?? '',
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
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

  /// Maps SQLite row to model (used by local datasource)
  factory SubmissionSummaryModel.fromMap(Map<String, dynamic> map) {
    return SubmissionSummaryModel(
      id: map['id'] as String,
      studentId: map['user_id'] as String? ?? '',
      studentName: map['student_name'] as String? ?? '',
      studentUsername: map['student_username'] as String? ?? '',
      startedAt: _parseUtc(map['started_at'] as String),
      submittedAt: map['submitted_at'] != null
          ? _parseUtc(map['submitted_at'] as String)
          : null,
      autoScore: (map['earned_points'] as num?)?.toDouble() ?? 0.0,
      finalScore: (map['earned_points'] as num?)?.toDouble() ?? 0.0,
      isSubmitted: map['submitted_at'] != null,
      assessmentId: map['assessment_id'] as String? ?? '',
      totalPoints: (map['total_points'] as num?)?.toInt() ?? 0,
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
      'user_id': studentId,
      'started_at': startedAt.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'total_points': totalPoints,
      'earned_points': autoScore,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'cached_at': cachedAt?.toIso8601String(),
      'needs_sync': needsSync ? 1 : 0,
    };
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
    required super.totalPoints,
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
      autoScore: (json['auto_score'] as num? ?? 0).toDouble(),
      finalScore: (json['final_score'] as num? ?? 0).toDouble(),
      isSubmitted: json['submitted_at'] != null,
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
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
    super.isPendingEssayGrade,
  });

  factory SubmissionAnswerModel.fromJson(Map<String, dynamic> json) {
    return SubmissionAnswerModel(
      id: json['id'] as String,
      questionId: json['question_id'] as String,
      questionText: json['question_text'] as String,
      questionType: json['question_type'] as String,
      points: (json['question_points'] as num?)?.toInt() ?? 0,
      answerText: json['answer_text'] as String?,
      selectedChoices: (json['selected_choices'] as List<dynamic>?)
          ?.map((e) =>
              SelectedChoiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      enumerationAnswers: (json['enumeration_answers'] as List<dynamic>?)
          ?.map((e) =>
              EnumerationAnswerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isAutoCorrect: null,
      isOverrideCorrect: null,
      pointsAwarded: (json['points_earned'] as num? ?? 0).toDouble(),
      isPendingEssayGrade: json['is_pending_essay_grade'] as bool? ?? false,
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
      isCorrect: json['is_correct'] as bool? ?? false,
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
    required super.isCorrect,
  });

  factory EnumerationAnswerModel.fromJson(Map<String, dynamic> json) {
    return EnumerationAnswerModel(
      id: json['id'] as String? ?? json['answer_text'] as String? ?? '',
      answerText: json['answer_text'] as String,
      matchedItemId: null,
      isAutoCorrect: null,
      isOverrideCorrect: null,
      isCorrect: json['is_correct'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'answer_text': answerText,
    'matched_item_id': matchedItemId,
    'is_auto_correct': isAutoCorrect,
    'is_override_correct': isOverrideCorrect,
    'is_correct': isCorrect,
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
      autoScore: (json['total_earned'] as num? ?? 0).toDouble(),
      finalScore: (json['total_earned'] as num? ?? 0).toDouble(),
      totalPoints: (json['total_possible'] as num?)?.toInt() ?? 0,
      submittedAt: json['submitted_at'] != null
          ? _parseUtc(json['submitted_at'] as String)
          : null,
      answers: (json['answers'] as List<dynamic>)
          .map((e) => StudentAnswerResultModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'submission_id': submissionId,
    'total_earned': autoScore,
    'total_possible': totalPoints,
    'submitted_at': submittedAt?.toIso8601String(),
    'answers': (answers as List<StudentAnswerResultModel>)
        .map((e) => e.toJson())
        .toList(),
  };
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
    super.isPendingEssayGrade,
  });

  factory StudentAnswerResultModel.fromJson(Map<String, dynamic> json) {
    return StudentAnswerResultModel(
      questionId: json['question_id'] as String,
      questionText: json['question_text'] as String,
      questionType: json['question_type'] as String,
      points: json['points'] as int? ?? json['question_points'] as int? ?? 0,
      pointsAwarded: (json['points_awarded'] as num? ?? json['points_earned'] as num? ?? 0).toDouble(),
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
      isPendingEssayGrade: json['is_pending_essay_grade'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'question_text': questionText,
    'question_type': questionType,
    'question_points': points,
    'points_earned': pointsAwarded,
    'is_correct': isCorrect,
    'answer_text': answerText,
    'selected_choices': selectedChoices,
    'enumeration_answers': enumerationAnswers
        ?.map((e) => (e as StudentEnumAnswerResultModel).toJson())
        .toList(),
    'correct_answers': correctAnswers,
  };
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

  Map<String, dynamic> toJson() => {
    'answer_text': answerText,
    'is_correct': isCorrect,
  };
}
