import 'dart:math';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/assessments/statistics_model.dart';

/// Computes assessment statistics locally from synced SQLite data.
///
/// This mirrors the server-side computation in `get_statistics.rs` and
/// `compute_item_analysis.rs`, allowing the client to render statistics
/// offline without waiting for a server response.
Future<AssessmentStatisticsModel?> computeStatistics(
  LocalDatabase localDatabase,
  String assessmentId,
) async {
  try {
    final db = await localDatabase.database;

    // 1. Fetch assessment metadata
    final assessmentRows = await db.query(
      DbTables.assessments,
      where: '${CommonCols.id} = ?',
      whereArgs: [assessmentId],
      limit: 1,
    );
    if (assessmentRows.isEmpty) return null;
    final assessmentRow = assessmentRows.first;
    final title = assessmentRow[AssessmentsCols.title] as String? ?? '';
    final totalPoints =
        (assessmentRow[AssessmentsCols.totalPoints] as num?)?.toInt() ?? 0;

    // 2. Fetch submitted submissions
    final submissionRows = await db.query(
      DbTables.assessmentSubmissions,
      where:
          '${AssessmentSubmissionsCols.assessmentId} = ? AND ${AssessmentSubmissionsCols.submittedAt} IS NOT NULL AND ${CommonCols.deletedAt} IS NULL',
      whereArgs: [assessmentId],
    );
    if (submissionRows.isEmpty) {
      return AssessmentStatisticsModel(
        assessmentId: assessmentId,
        title: title,
        totalPoints: totalPoints,
        submissionCount: 0,
        classStatistics: const ClassStatisticsModel(
          mean: 0,
          median: 0,
          stdDev: 0,
          highest: 0,
          lowest: 0,
          passRate: 0,
          failRate: 0,
          scoreDistribution: [],
        ),
        questionStatistics: const [],
        itemAnalysis: const [],
      );
    }

    final submissionCount = submissionRows.length;
    final submissionIds = submissionRows.map((r) => r[CommonCols.id] as String).toList();

    // Extract scores
    final scores = submissionRows
        .map((r) => (r[AssessmentSubmissionsCols.totalPoints] as num?)?.toDouble() ?? 0.0)
        .toList();

    // 3. Compute class statistics
    final classStatistics = _computeClassStatistics(scores, totalPoints);

    // 4. Fetch questions for this assessment (non-deleted)
    final questionRows = await db.query(
      DbTables.assessmentQuestions,
      where:
          '${AssessmentQuestionsCols.assessmentId} = ? AND ${CommonCols.deletedAt} IS NULL',
      whereArgs: [assessmentId],
      orderBy: '${AssessmentQuestionsCols.orderIndex} ASC',
    );

    final questions = <_QuestionData>[];
    for (final row in questionRows) {
      questions.add(_QuestionData(
        id: row[CommonCols.id] as String,
        questionType: row[AssessmentQuestionsCols.questionType] as String,
        questionText: row[AssessmentQuestionsCols.questionText] as String,
        points: (row[AssessmentQuestionsCols.points] as num?)?.toInt() ?? 0,
        isMultiSelect:
            (row[AssessmentQuestionsCols.isMultiSelect] as num?)?.toInt() == 1,
      ));
    }

    // 5. Fetch all submission_answers for these submissions
    final placeholders = List.filled(submissionIds.length, '?').join(',');
    final answerRows = await db.rawQuery(
      'SELECT * FROM ${DbTables.submissionAnswers} WHERE ${SubmissionAnswersCols.submissionId} IN ($placeholders)',
      submissionIds,
    );

    // Map: (studentId, questionId) -> answerPoints
    final studentQuestionPoints = <String, Map<String, double>>{};
    // Map: answerId -> questionId
    final answerIdToQuestionId = <String, String>{};
    // Map: answerId -> submissionId
    final answerIdToSubmissionId = <String, String>{};

    // Build submissionId -> studentId map
    final submissionToStudent = <String, String>{};
    for (final row in submissionRows) {
      submissionToStudent[row[CommonCols.id] as String] =
          row[AssessmentSubmissionsCols.userId] as String;
    }

    for (final row in answerRows) {
      final answerId = row[CommonCols.id] as String;
      final submissionId = row[SubmissionAnswersCols.submissionId] as String;
      final questionId = row[SubmissionAnswersCols.questionId] as String;
      final points =
          (row[SubmissionAnswersCols.points] as num?)?.toDouble() ?? 0.0;

      answerIdToQuestionId[answerId] = questionId;
      answerIdToSubmissionId[answerId] = submissionId;

      final studentId = submissionToStudent[submissionId];
      if (studentId != null) {
        studentQuestionPoints
            .putIfAbsent(studentId, () => {})[questionId] = points;
      }
    }

    // 6. Fetch all submission_answer_items for these answers
    final answerIds = answerRows.map((r) => r[CommonCols.id] as String).toList();
    final Map<String, List<_AnswerItemData>> answerItemsMap = {};
    if (answerIds.isNotEmpty) {
      final itemPlaceholders = List.filled(answerIds.length, '?').join(',');
      final itemRows = await db.rawQuery(
        'SELECT * FROM ${DbTables.submissionAnswerItems} WHERE ${SubmissionAnswerItemsCols.submissionAnswerId} IN ($itemPlaceholders)',
        answerIds,
      );
      for (final row in itemRows) {
        final answerId = row[SubmissionAnswerItemsCols.submissionAnswerId] as String;
        answerItemsMap.putIfAbsent(answerId, () => []);
        answerItemsMap[answerId]!.add(_AnswerItemData(
          choiceId: row[SubmissionAnswerItemsCols.choiceId] as String?,
          isCorrect: (row[SubmissionAnswerItemsCols.isCorrect] as num?)?.toInt() == 1,
        ));
      }
    }

    // 7. Compute per-question correct/incorrect counts
    // student_question_correct: (studentId, questionId) -> isCorrect
    final studentQuestionCorrect = <String, Set<String>>{};
    final studentQuestionIncorrect = <String, Set<String>>{};

    // Build per-student-per-question data
    for (final row in answerRows) {
      final submissionId = row[SubmissionAnswersCols.submissionId] as String;
      final questionId = row[SubmissionAnswersCols.questionId] as String;
      final points =
          (row[SubmissionAnswersCols.points] as num?)?.toDouble() ?? 0.0;
      final studentId = submissionToStudent[submissionId];
      if (studentId == null) continue;

      final isCorrect = points > 0.0;
      if (isCorrect) {
        studentQuestionCorrect
            .putIfAbsent(studentId, () => {})
            .add(questionId);
      } else {
        studentQuestionIncorrect
            .putIfAbsent(studentId, () => {})
            .add(questionId);
      }
    }

    // Aggregate correct/incorrect counts per question
    final correctCounts = <String, int>{};
    final incorrectCounts = <String, int>{};
    for (final studentId in studentQuestionCorrect.keys) {
      for (final qId in studentQuestionCorrect[studentId]!) {
        correctCounts[qId] = (correctCounts[qId] ?? 0) + 1;
      }
    }
    for (final studentId in studentQuestionIncorrect.keys) {
      for (final qId in studentQuestionIncorrect[studentId]!) {
        incorrectCounts[qId] = (incorrectCounts[qId] ?? 0) + 1;
      }
    }

    // Build question statistics
    final questionStats = <QuestionStatisticsModel>[];
    for (final q in questions) {
      final correctCount = correctCounts[q.id] ?? 0;
      final incorrectCount = incorrectCounts[q.id] ?? 0;
      final totalAnswered = correctCount + incorrectCount;
      final correctPercentage = totalAnswered > 0
          ? (correctCount / totalAnswered) * 100.0
          : 0.0;

      questionStats.add(QuestionStatisticsModel(
        questionId: q.id,
        questionText: q.questionText,
        questionType: q.questionType,
        points: q.points,
        correctCount: correctCount,
        incorrectCount: incorrectCount,
        correctPercentage: correctPercentage,
      ));
    }

    // 8. Compute item analysis if >= 10 submissions
    List<ItemAnalysisModel> itemAnalysis = [];
    TestSummaryModel? testSummary;

    if (submissionCount >= 10) {
      // Sort students by score descending
      final sortedStudents = <_StudentScore>[];
      for (final row in submissionRows) {
        sortedStudents.add(_StudentScore(
          studentId: row[AssessmentSubmissionsCols.userId] as String,
          totalPoints:
              (row[AssessmentSubmissionsCols.totalPoints] as num?)?.toDouble() ?? 0.0,
        ));
      }
      sortedStudents.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

      final n = (0.27 * submissionCount).ceil();
      final groupSize = n < 3 ? 3 : n;

      final upperGroup = <String>{};
      final lowerGroup = <String>{};
      for (var i = 0; i < groupSize && i < sortedStudents.length; i++) {
        upperGroup.add(sortedStudents[i].studentId);
      }
      for (var i = sortedStudents.length - 1;
          i >= sortedStudents.length - groupSize && i >= 0;
          i--) {
        lowerGroup.add(sortedStudents[i].studentId);
      }

      final upperSize = upperGroup.length.toDouble();
      final lowerSize = lowerGroup.length.toDouble();

      // Pre-compute correct counts per question for upper/lower groups
      final upperCorrect = <String, int>{};
      final lowerCorrect = <String, int>{};
      for (final studentId in studentQuestionCorrect.keys) {
        for (final qId in studentQuestionCorrect[studentId]!) {
          if (upperGroup.contains(studentId)) {
            upperCorrect[qId] = (upperCorrect[qId] ?? 0) + 1;
          }
          if (lowerGroup.contains(studentId)) {
            lowerCorrect[qId] = (lowerCorrect[qId] ?? 0) + 1;
          }
        }
      }

      // Build student_question_choices for distractor analysis
      // (studentId, questionId) -> [(choiceId, isCorrect)]
      final studentChoices = <String, Map<String, List<(String?, bool)>>>{};
      for (final row in answerRows) {
        final answerId = row[CommonCols.id] as String;
        final submissionId = row[SubmissionAnswersCols.submissionId] as String;
        final questionId = row[SubmissionAnswersCols.questionId] as String;
        final studentId = submissionToStudent[submissionId];
        if (studentId == null) continue;

        final items = answerItemsMap[answerId] ?? [];
        for (final item in items) {
          studentChoices
              .putIfAbsent(studentId, () => {})
              .putIfAbsent(questionId, () => [])
              .add((item.choiceId, item.isCorrect));
        }
      }

      // Pre-compute distractor selection counts: (questionId, choiceId) -> (total, upper, lower)
      final choiceSelections = <String, Map<String, (int, int, int)>>{};
      for (final studentId in studentChoices.keys) {
        final questionMap = studentChoices[studentId]!;
        for (final entry in questionMap.entries) {
          final qId = entry.key;
          final selections = entry.value;
          for (final (choiceIdOpt, _) in selections) {
            if (choiceIdOpt != null) {
              final qMap = choiceSelections.putIfAbsent(qId, () => {});
              final (total, upper, lower) = qMap[choiceIdOpt] ?? (0, 0, 0);
              qMap[choiceIdOpt] = (
                total + 1,
                upper + (upperGroup.contains(studentId) ? 1 : 0),
                lower + (lowerGroup.contains(studentId) ? 1 : 0),
              );
            }
          }
        }
      }

      // Fetch choices for MC questions
      final mcQuestionIds = questions
          .where((q) => q.questionType == 'multiple_choice')
          .map((q) => q.id)
          .toList();
      final questionChoicesMap = <String, List<(String, String, bool)>>{};
      if (mcQuestionIds.isNotEmpty) {
        final choicePlaceholders = List.filled(mcQuestionIds.length, '?').join(',');
        final choiceRows = await db.rawQuery(
          'SELECT * FROM ${DbTables.questionChoices} WHERE ${QuestionChoicesCols.questionId} IN ($choicePlaceholders) ORDER BY ${QuestionChoicesCols.orderIndex} ASC',
          mcQuestionIds,
        );
        for (final row in choiceRows) {
          final qId = row[QuestionChoicesCols.questionId] as String;
          questionChoicesMap.putIfAbsent(qId, () => []);
          questionChoicesMap[qId]!.add((
            row[CommonCols.id] as String,
            row[QuestionChoicesCols.choiceText] as String,
            (row[QuestionChoicesCols.isCorrect] as num?)?.toInt() == 1,
          ));
        }
      }

      // Compute item analysis per question
      double totalP = 0.0;
      double totalD = 0.0;
      int retainCount = 0;
      int reviseCount = 0;
      int discardCount = 0;

      for (final q in questions) {
        final ru = upperCorrect[q.id] ?? 0;
        final rl = lowerCorrect[q.id] ?? 0;

        final p = (upperSize + lowerSize) > 0
            ? (ru + rl) / (upperSize + lowerSize)
            : 0.0;
        final d = (upperSize > 0 && lowerSize > 0)
            ? (ru / upperSize) - (rl / lowerSize)
            : 0.0;

        final difficultyLabel = _getDifficultyLabel(p);
        final discriminationLabel = _getDiscriminationLabel(d);
        final verdict = _getVerdict(p, d);

        totalP += p;
        totalD += d;
        switch (verdict) {
          case 'retain':
            retainCount++;
          case 'revise':
            reviseCount++;
          case 'discard':
            discardCount++;
        }

        // Distractor analysis for MC questions
        List<DistractorAnalysisModel>? distractors;
        if (q.questionType == 'multiple_choice') {
          final choices = questionChoicesMap[q.id];
          if (choices != null) {
            distractors = [];
            for (final (choiceId, choiceText, isCorrect) in choices) {
              final (totalSelected, upperCount, lowerCount) =
                  choiceSelections[q.id]?[choiceId] ?? (0, 0, 0);
              final totalPercentage = submissionCount > 0
                  ? (totalSelected / submissionCount) * 100.0
                  : 0.0;
              final isEffective =
                  isCorrect ? true : lowerCount > upperCount;

              distractors.add(DistractorAnalysisModel(
                choiceId: choiceId,
                choiceText: choiceText,
                isCorrect: isCorrect,
                upperCount: upperCount,
                lowerCount: lowerCount,
                totalPercentage: totalPercentage,
                isEffective: isEffective,
              ));
            }
          }
        }

        itemAnalysis.add(ItemAnalysisModel(
          questionId: q.id,
          questionText: q.questionText,
          questionType: q.questionType,
          points: q.points,
          difficultyIndex: p,
          difficultyLabel: difficultyLabel,
          discriminationIndex: d,
          discriminationLabel: discriminationLabel,
          verdict: verdict,
          distractors: distractors,
        ));
      }

      final totalItems = itemAnalysis.length;
      if (totalItems > 0) {
        double? kr20;
        final nStudents = submissionCount.toDouble();
        final k = totalItems.toDouble();
        if (k > 1.0 && nStudents > 1.0) {
          final allCorrect = <String, int>{};
          for (final entry in studentQuestionCorrect.entries) {
            for (final qId in entry.value) {
              allCorrect[qId] = (allCorrect[qId] ?? 0) + 1;
            }
          }
          double pqSum = 0.0;
          for (final q in questions) {
            final correct = allCorrect[q.id] ?? 0;
            final pI = correct / nStudents;
            pqSum += pI * (1.0 - pI);
          }
          final studentCorrect = <String, int>{};
          for (final entry in studentQuestionCorrect.entries) {
            studentCorrect[entry.key] = entry.value.length;
          }
          final correctCounts = sortedStudents
              .map((s) => studentCorrect[s.studentId]?.toDouble() ?? 0.0)
              .toList();
          final meanCorrect =
              correctCounts.reduce((a, b) => a + b) / nStudents;
          final variance = correctCounts
                  .map((c) => pow(c - meanCorrect, 2).toDouble())
                  .reduce((a, b) => a + b) /
              nStudents;
          if (variance > 0.0) {
            kr20 = (k / (k - 1.0)) * (1.0 - pqSum / variance);
          }
        }

        testSummary = TestSummaryModel(
          meanDifficulty: totalP / totalItems,
          meanDiscrimination: totalD / totalItems,
          retainCount: retainCount,
          reviseCount: reviseCount,
          discardCount: discardCount,
          totalItemsAnalyzed: totalItems,
          upperGroupSize: upperGroup.length,
          lowerGroupSize: lowerGroup.length,
          kr20: kr20,
        );
      }
    }

    return AssessmentStatisticsModel(
      assessmentId: assessmentId,
      title: title,
      totalPoints: totalPoints,
      submissionCount: submissionCount,
      classStatistics: classStatistics,
      questionStatistics: questionStats,
      itemAnalysis: itemAnalysis,
      testSummary: testSummary,
    );
  } catch (e) {
    return null;
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

ClassStatisticsModel _computeClassStatistics(List<double> scores, int totalPoints) {
  final sorted = List<double>.from(scores)..sort();
  final n = sorted.length;

  final mean = scores.reduce((a, b) => a + b) / n;
  final median = n % 2 == 0
      ? (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2.0
      : sorted[n ~/ 2];
  final highest = sorted.last;
  final lowest = sorted.first;

  final variance =
      scores.map((s) { final d = s - mean; return d * d; }).reduce((a, b) => a + b) / n;
  final stdDev = sqrt(variance);

  double passRate = 0.0;
  double failRate = 0.0;
  if (totalPoints > 0) {
    final passThreshold = totalPoints * 0.75;
    final passCount = scores.where((s) => s >= passThreshold).length;
    passRate = (passCount / n) * 100.0;
    failRate = 100.0 - passRate;
  }

  List<ScoreBucketModel> distribution = [];
  if (totalPoints > 0) {
    final scoreMap = <int, int>{};
    for (final s in scores) {
      final bucket = s.floor().toInt();
      scoreMap[bucket] = (scoreMap[bucket] ?? 0) + 1;
    }
    distribution = scoreMap.entries
        .map((e) => ScoreBucketModel(score: e.key, count: e.value))
        .toList()
      ..sort((a, b) => a.score.compareTo(b.score));
  }

  return ClassStatisticsModel(
    mean: mean,
    median: median,
    stdDev: stdDev,
    highest: highest,
    lowest: lowest,
    passRate: passRate,
    failRate: failRate,
    scoreDistribution: distribution,
  );
}

String _getDifficultyLabel(double p) {
  if (p >= 0.86) return 'Very Easy';
  if (p >= 0.71) return 'Easy';
  if (p >= 0.30) return 'Moderate';
  if (p >= 0.15) return 'Difficult';
  return 'Very Difficult';
}

String _getDiscriminationLabel(double d) {
  if (d >= 0.40) return 'Very Good';
  if (d >= 0.30) return 'Reasonably Good';
  if (d >= 0.20) return 'Marginal';
  return 'Poor';
}

String _getVerdict(double p, double d) {
  final dTier = d >= 0.40 ? 3 : d >= 0.30 ? 2 : d >= 0.20 ? 1 : 0;
  final pTier = p >= 0.86 ? 4 : p >= 0.71 ? 3 : p >= 0.30 ? 0 : p >= 0.15 ? 2 : 4;

  switch ((pTier, dTier)) {
    case (0, 3):
    case (0, 2):
      return 'retain';
    case (0, 1):
    case (0, 0):
      return 'revise';
    case (3, 3):
      return 'retain';
    case (3, 2):
    case (3, 1):
    case (3, 0):
      return 'revise';
    case (2, 3):
      return 'retain';
    case (2, 2):
    case (2, 1):
    case (2, 0):
      return 'revise';
    default:
      return 'discard';
  }
}

// ─── Internal data classes ────────────────────────────────────────────────────

class _QuestionData {
  final String id;
  final String questionType;
  final String questionText;
  final int points;
  final bool isMultiSelect;

  _QuestionData({
    required this.id,
    required this.questionType,
    required this.questionText,
    required this.points,
    required this.isMultiSelect,
  });
}

class _StudentScore {
  final String studentId;
  final double totalPoints;

  _StudentScore({required this.studentId, required this.totalPoints});
}

class _AnswerItemData {
  final String? choiceId;
  final bool isCorrect;

  _AnswerItemData({required this.choiceId, required this.isCorrect});
}
