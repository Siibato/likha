import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';

/// Immutable raw rows fetched from SQLite for statistics computation.
/// No computation logic — only data shaping.
class SubmissionRow {
  final String id;
  final String userId;
  final double totalPoints;

  const SubmissionRow({
    required this.id,
    required this.userId,
    required this.totalPoints,
  });
}

class QuestionRow {
  final String id;
  final String questionType;
  final String questionText;
  final int points;
  final bool isMultiSelect;

  const QuestionRow({
    required this.id,
    required this.questionType,
    required this.questionText,
    required this.points,
    required this.isMultiSelect,
  });
}

class AnswerRow {
  final String id;
  final String submissionId;
  final String questionId;
  final double? points;

  const AnswerRow({
    required this.id,
    required this.submissionId,
    required this.questionId,
    this.points,
  });
}

class AnswerItemRow {
  final String submissionAnswerId;
  final String? choiceId;
  final bool isCorrect;

  const AnswerItemRow({
    required this.submissionAnswerId,
    this.choiceId,
    required this.isCorrect,
  });
}

class ChoiceRow {
  final String id;
  final String questionId;
  final String choiceText;
  final bool isCorrect;

  const ChoiceRow({
    required this.id,
    required this.questionId,
    required this.choiceText,
    required this.isCorrect,
  });
}

class StatisticsRawData {
  final String assessmentId;
  final String title;
  final int totalPoints;
  final List<SubmissionRow> submissions;
  final List<QuestionRow> questions;
  final List<AnswerRow> answers;
  final List<AnswerItemRow> answerItems;
  final List<ChoiceRow> choices;

  const StatisticsRawData({
    required this.assessmentId,
    required this.title,
    required this.totalPoints,
    required this.submissions,
    required this.questions,
    required this.answers,
    required this.answerItems,
    required this.choices,
  });

  int get submissionCount => submissions.length;

  /// Data is complete enough for statistics only when most submissions
  /// have corresponding answers. The background refresh for submission
  /// lists only caches summaries (no answers), so we must guard against
  /// computing item analysis from a handful of cached answers.
  bool get isComplete {
    if (submissions.isEmpty || answers.isEmpty) return false;

    // At least some answers must have real graded scores
    // (draft answers saved locally before submission have points=null)
    if (!answers.any((a) => a.points != null)) return false;

    // Count how many distinct submissions actually have answer rows
    final submissionsWithAnswers = answers.map((a) => a.submissionId).toSet().length;

    // Require at least 80% of submissions to have answers, or all if < 10 subs
    final threshold = submissions.length < 10 ? submissions.length : (submissions.length * 0.8).ceil();

    return submissionsWithAnswers >= threshold;
  }
}

/// Fetches raw rows from SQLite. No computation, no business logic.
class StatisticsDataFetcher {
  final LocalDatabase _localDatabase;

  StatisticsDataFetcher(this._localDatabase);

  Future<StatisticsRawData> fetchAll(String assessmentId) async {
    final db = await _localDatabase.database;

    final assessmentRows = await db.query(
      DbTables.assessments,
      where: '${CommonCols.id} = ?',
      whereArgs: [assessmentId],
      limit: 1,
    );

    final title = assessmentRows.isNotEmpty
        ? (assessmentRows.first[AssessmentsCols.title] as String? ?? '')
        : '';
    final totalPoints = assessmentRows.isNotEmpty
        ? ((assessmentRows.first[AssessmentsCols.totalPoints] as num?)?.toInt() ?? 0)
        : 0;

    final submissionRows = await db.query(
      DbTables.assessmentSubmissions,
      where:
          '${AssessmentSubmissionsCols.assessmentId} = ? AND ${AssessmentSubmissionsCols.submittedAt} IS NOT NULL AND ${CommonCols.deletedAt} IS NULL',
      whereArgs: [assessmentId],
    );

    final submissions = submissionRows.map((r) => SubmissionRow(
      id: r[CommonCols.id] as String,
      userId: r[AssessmentSubmissionsCols.userId] as String,
      totalPoints: (r[AssessmentSubmissionsCols.earnedPoints] as num?)?.toDouble() ?? 0.0,
    )).toList();

    final questionRows = await db.query(
      DbTables.assessmentQuestions,
      where:
          '${AssessmentQuestionsCols.assessmentId} = ? AND ${CommonCols.deletedAt} IS NULL',
      whereArgs: [assessmentId],
      orderBy: '${AssessmentQuestionsCols.orderIndex} ASC',
    );

    final questions = questionRows.map((r) => QuestionRow(
      id: r[CommonCols.id] as String,
      questionType: r[AssessmentQuestionsCols.questionType] as String,
      questionText: r[AssessmentQuestionsCols.questionText] as String,
      points: (r[AssessmentQuestionsCols.points] as num?)?.toInt() ?? 0,
      isMultiSelect: (r[AssessmentQuestionsCols.isMultiSelect] as num?)?.toInt() == 1,
    )).toList();

    final submissionIds = submissions.map((s) => s.id).toList();
    List<AnswerRow> answers = [];
    if (submissionIds.isNotEmpty) {
      final placeholders = List.filled(submissionIds.length, '?').join(',');
      final answerRows = await db.rawQuery(
        'SELECT * FROM ${DbTables.submissionAnswers} WHERE ${SubmissionAnswersCols.submissionId} IN ($placeholders)',
        submissionIds,
      );
      answers = answerRows.map((r) => AnswerRow(
        id: r[CommonCols.id] as String,
        submissionId: r[SubmissionAnswersCols.submissionId] as String,
        questionId: r[SubmissionAnswersCols.questionId] as String,
        points: (r[SubmissionAnswersCols.points] as num?)?.toDouble(),
      )).toList();
    }

    final answerIds = answers.map((a) => a.id).toList();
    List<AnswerItemRow> answerItems = [];
    if (answerIds.isNotEmpty) {
      final placeholders = List.filled(answerIds.length, '?').join(',');
      final itemRows = await db.rawQuery(
        'SELECT * FROM ${DbTables.submissionAnswerItems} WHERE ${SubmissionAnswerItemsCols.submissionAnswerId} IN ($placeholders)',
        answerIds,
      );
      answerItems = itemRows.map((r) => AnswerItemRow(
        submissionAnswerId: r[SubmissionAnswerItemsCols.submissionAnswerId] as String,
        choiceId: r[SubmissionAnswerItemsCols.choiceId] as String?,
        isCorrect: (r[SubmissionAnswerItemsCols.isCorrect] as num?)?.toInt() == 1,
      )).toList();
    }

    final questionIds = questions.map((q) => q.id).toList();
    List<ChoiceRow> choices = [];
    if (questionIds.isNotEmpty) {
      final placeholders = List.filled(questionIds.length, '?').join(',');
      final choiceRows = await db.rawQuery(
        'SELECT * FROM ${DbTables.questionChoices} WHERE ${QuestionChoicesCols.questionId} IN ($placeholders) ORDER BY ${QuestionChoicesCols.orderIndex} ASC',
        questionIds,
      );
      choices = choiceRows.map((r) => ChoiceRow(
        id: r[CommonCols.id] as String,
        questionId: r[QuestionChoicesCols.questionId] as String,
        choiceText: r[QuestionChoicesCols.choiceText] as String,
        isCorrect: (r[QuestionChoicesCols.isCorrect] as num?)?.toInt() == 1,
      )).toList();
    }

    return StatisticsRawData(
      assessmentId: assessmentId,
      title: title,
      totalPoints: totalPoints,
      submissions: submissions,
      questions: questions,
      answers: answers,
      answerItems: answerItems,
      choices: choices,
    );
  }
}
