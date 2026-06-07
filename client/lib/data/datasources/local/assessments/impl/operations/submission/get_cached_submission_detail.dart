import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/security/encryption_service.dart';
import 'package:likha/data/models/assessments/submission_model.dart';

Future<SubmissionDetailModel?> getCachedSubmissionDetailOp(
  LocalDatabase localDatabase,
  EncryptionService enc,
  String submissionId,
) async {
  try {
    RepoLogger.instance.log('getCachedSubmissionDetail: START for $submissionId');
    final db = await localDatabase.database;
    final results = await db.rawQuery('''
      SELECT s.*, u.full_name as student_name
      FROM assessment_submissions s
      LEFT JOIN users u ON u.id = s.user_id
      WHERE s.id = ? AND s.deleted_at IS NULL
    ''', [submissionId]);
    if (results.isEmpty) {
      RepoLogger.instance.log('getCachedSubmissionDetail: no submission row found for $submissionId');
      return null;
    }
    final sub = results.first;

    final answerRows = await db.rawQuery('''
      SELECT sa.id as answer_id, sa.question_id, sa.points as points_awarded,
             sa.overridden_by,
             aq.question_text, aq.question_type, aq.points as question_points,
             aq.order_index
      FROM submission_answers sa
      JOIN assessment_questions aq ON aq.id = sa.question_id
      WHERE sa.submission_id = ?
      ORDER BY aq.order_index ASC
    ''', [submissionId]);
    RepoLogger.instance.log('getCachedSubmissionDetail: found ${answerRows.length} answer rows for $submissionId');

    final List<SubmissionAnswerModel> answers = [];
    for (final row in answerRows) {
      final answerId = row['answer_id'] as String;
      final questionType = row['question_type'] as String;
      final questionText = enc.decryptField(row['question_text'] as String?) ?? '';

      final itemRows = await db.rawQuery('''
        SELECT sai.id, sai.choice_id, sai.answer_text, sai.is_correct, qc.choice_text
        FROM submission_answer_items sai
        LEFT JOIN question_choices qc ON qc.id = sai.choice_id
        WHERE sai.submission_answer_id = ?
      ''', [answerId]);

      List<SelectedChoiceModel>? selectedChoices;
      List<EnumerationAnswerModel>? enumerationAnswers;
      String? answerText;

      if (questionType == 'multiple_choice') {
        selectedChoices = itemRows
            .map((item) => SelectedChoiceModel(
                  choiceId: item['choice_id'] as String? ?? '',
                  choiceText: enc.decryptField(item['choice_text'] as String?) ?? '',
                  isCorrect: (item['is_correct'] as int?) == 1,
                ))
            .toList();
      } else if (questionType == 'enumeration') {
        enumerationAnswers = itemRows
            .map((item) => EnumerationAnswerModel(
                  id: item['id'] as String,
                  answerText: item['answer_text'] as String? ?? '',
                  isCorrect: (item['is_correct'] as int?) == 1,
                ))
            .toList();
      } else {
        answerText = itemRows.isNotEmpty ? itemRows.first['answer_text'] as String? : null;
      }

      final pointsAwarded = (row['points_awarded'] as num?)?.toDouble() ?? 0.0;

      answers.add(SubmissionAnswerModel(
        id: answerId,
        questionId: row['question_id'] as String,
        questionText: questionText,
        questionType: questionType,
        points: (row['question_points'] as num?)?.toInt() ?? 0,
        answerText: answerText,
        selectedChoices: selectedChoices,
        enumerationAnswers: enumerationAnswers,
        isAutoCorrect: null,
        isOverrideCorrect: null,
        pointsAwarded: pointsAwarded,
        isPendingEssayGrade: false,
      ));
    }

    RepoLogger.instance.log('getCachedSubmissionDetail: built model with ${answers.length} answers for $submissionId');
    return SubmissionDetailModel(
      id: sub['id'] as String,
      assessmentId: sub['assessment_id'] as String? ?? '',
      studentId: sub['user_id'] as String? ?? '',
      studentName: enc.decryptField(sub['student_name'] as String?) ?? '',
      startedAt: DateTime.parse(sub['started_at'] as String),
      submittedAt: sub['submitted_at'] != null ? DateTime.parse(sub['submitted_at'] as String) : null,
      autoScore: (sub['earned_points'] as num?)?.toDouble() ?? 0.0,
      finalScore: (sub['earned_points'] as num?)?.toDouble() ?? 0.0,
      isSubmitted: sub['submitted_at'] != null,
      totalPoints: (sub['total_points'] as num?)?.toDouble() ?? 0.0,
      answers: answers,
    );
  } catch (e) {
    RepoLogger.instance.log('getCachedSubmissionDetail: ERROR for $submissionId: $e');
    throw CacheException('Failed to get cached submission detail: $e');
  }
}
