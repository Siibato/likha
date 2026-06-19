import 'dart:math';

import 'package:likha/data/datasources/local/assessments/operations/statistics_data_fetcher.dart';
import 'package:likha/data/models/assessments/statistics_model.dart';

/// Pure computation layer for assessment statistics.
/// No database access, no side effects. Immutable in, immutable out.
class StatisticsComputer {
  const StatisticsComputer._();

  static AssessmentStatisticsModel compute(StatisticsRawData data) {
    final scores = data.submissions.map((s) => s.totalPoints).toList();
    final classStatistics = _computeClassStatistics(scores, data.totalPoints);

    final submissionToStudent = <String, String>{};
    for (final s in data.submissions) {
      submissionToStudent[s.id] = s.userId;
    }

    final answerItemsByAnswer = <String, List<AnswerItemRow>>{};
    for (final item in data.answerItems) {
      answerItemsByAnswer.putIfAbsent(item.submissionAnswerId, () => []).add(item);
    }

    final questionMap = <String, QuestionRow>{};
    for (final q in data.questions) {
      questionMap[q.id] = q;
    }

    // (studentId, questionId) -> points
    final studentQuestionPoints = <String, Map<String, double>>{};
    // (studentId, questionId) -> isCorrect (binary)
    final studentQuestionCorrect = <String, Map<String, bool>>{};

    for (final answer in data.answers) {
      final studentId = submissionToStudent[answer.submissionId];
      if (studentId == null) continue;

      final points = answer.points ?? 0.0;
      studentQuestionPoints
          .putIfAbsent(studentId, () => {})[answer.questionId] = points;

      final question = questionMap[answer.questionId];
      bool isCorrect;
      if (answer.points != null) {
        isCorrect = answer.points! > 0.0;
      } else {
        final items = answerItemsByAnswer[answer.id] ?? [];
        if (items.isNotEmpty) {
          isCorrect = items.any((i) => i.isCorrect);
        } else if (question != null) {
          isCorrect = points >= question.points;
        } else {
          isCorrect = false;
        }
      }
      studentQuestionCorrect
          .putIfAbsent(studentId, () => {})[answer.questionId] = isCorrect;
    }

    final questionStats = _computeQuestionStatistics(
      data.questions,
      studentQuestionPoints,
      studentQuestionCorrect,
    );

    final (itemAnalysis, testSummary) = data.submissionCount >= 10
        ? _computeItemAnalysis(
            data,
            submissionToStudent,
            studentQuestionPoints,
            studentQuestionCorrect,
            answerItemsByAnswer,
          )
        : (<ItemAnalysisModel>[], null);

    return AssessmentStatisticsModel(
      assessmentId: data.assessmentId,
      title: data.title,
      totalPoints: data.totalPoints,
      submissionCount: data.submissionCount,
      classStatistics: classStatistics,
      questionStatistics: questionStats,
      itemAnalysis: itemAnalysis,
      testSummary: testSummary,
    );
  }

  // ─── Class Statistics ──────────────────────────────────────────────────────

  static ClassStatisticsModel _computeClassStatistics(
    List<double> scores,
    int totalPoints,
  ) {
    if (scores.isEmpty) {
      return const ClassStatisticsModel(
        mean: 0,
        median: 0,
        stdDev: 0,
        highest: 0,
        lowest: 0,
        passRate: 0,
        failRate: 0,
        scoreDistribution: [],
      );
    }

    final sorted = List<double>.from(scores)..sort();
    final n = sorted.length;

    final mean = scores.reduce((a, b) => a + b) / n;
    final median = n % 2 == 0
        ? (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2.0
        : sorted[n ~/ 2];
    final highest = sorted.last;
    final lowest = sorted.first;

    final variance = scores.map((s) {
      final d = s - mean;
      return d * d;
    }).reduce((a, b) => a + b) / n;
    final stdDev = sqrt(variance);

    double passRate = 0.0;
    double failRate = 0.0;
    if (totalPoints > 0) {
      final passThreshold = totalPoints * 0.75;
      final passCount = scores.where((s) => s >= passThreshold).length;
      passRate = (passCount / n) * 100.0;
      failRate = 100.0 - passRate;
    }

    final scoreMap = <int, int>{};
    for (final s in scores) {
      final bucket = s.floor().toInt();
      scoreMap[bucket] = (scoreMap[bucket] ?? 0) + 1;
    }
    final distribution = scoreMap.entries
        .map((e) => ScoreBucketModel(score: e.key, count: e.value))
        .toList()
      ..sort((a, b) => a.score.compareTo(b.score));

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

  // ─── Question Statistics ───────────────────────────────────────────────────

  static List<QuestionStatisticsModel> _computeQuestionStatistics(
    List<QuestionRow> questions,
    Map<String, Map<String, double>> studentQuestionPoints,
    Map<String, Map<String, bool>> studentQuestionCorrect,
  ) {
    final result = <QuestionStatisticsModel>[];

    for (final q in questions) {
      int correctCount = 0;
      int incorrectCount = 0;
      double totalPoints = 0.0;
      int answeredCount = 0;

      for (final studentId in studentQuestionPoints.keys) {
        final points = studentQuestionPoints[studentId]?[q.id];
        if (points != null) {
          totalPoints += points;
          answeredCount++;
        }
      }

      for (final studentId in studentQuestionCorrect.keys) {
        final isCorrect = studentQuestionCorrect[studentId]?[q.id] ?? false;
        if (isCorrect) {
          correctCount++;
        } else {
          incorrectCount++;
        }
      }

      final totalAnswered = correctCount + incorrectCount;
      final correctPercentage = totalAnswered > 0
          ? (correctCount / totalAnswered) * 100.0
          : 0.0;

      final averagePoints = answeredCount > 0 ? totalPoints / answeredCount : 0.0;
      final averagePercentage =
          (q.points > 0 && answeredCount > 0) ? (averagePoints / q.points) * 100.0 : 0.0;

      result.add(QuestionStatisticsModel(
        questionId: q.id,
        questionText: q.questionText,
        questionType: q.questionType,
        points: q.points,
        correctCount: correctCount,
        incorrectCount: incorrectCount,
        correctPercentage: correctPercentage,
        averagePoints: averagePoints,
        averagePercentage: averagePercentage,
      ));
    }

    return result;
  }

  // ─── Item Analysis ─────────────────────────────────────────────────────────

  static (List<ItemAnalysisModel>, TestSummaryModel?) _computeItemAnalysis(
    StatisticsRawData data,
    Map<String, String> submissionToStudent,
    Map<String, Map<String, double>> studentQuestionPoints,
    Map<String, Map<String, bool>> studentQuestionCorrect,
    Map<String, List<AnswerItemRow>> answerItemsByAnswer,
  ) {
    final sortedStudents = data.submissions
        .map((s) => _StudentScore(studentId: s.userId, totalPoints: s.totalPoints))
        .toList()
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    final n = (0.27 * data.submissionCount).ceil();
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

    // Per-question average points for upper/lower groups
    final upperAvgByQuestion = <String, double>{};
    final lowerAvgByQuestion = <String, double>{};
    final upperCountByQuestion = <String, int>{};
    final lowerCountByQuestion = <String, int>{};

    for (final entry in studentQuestionPoints.entries) {
      final studentId = entry.key;
      final questionPoints = entry.value;
      for (final qEntry in questionPoints.entries) {
        final qId = qEntry.key;
        final points = qEntry.value;
        if (upperGroup.contains(studentId)) {
          upperAvgByQuestion[qId] = (upperAvgByQuestion[qId] ?? 0.0) + points;
          upperCountByQuestion[qId] = (upperCountByQuestion[qId] ?? 0) + 1;
        }
        if (lowerGroup.contains(studentId)) {
          lowerAvgByQuestion[qId] = (lowerAvgByQuestion[qId] ?? 0.0) + points;
          lowerCountByQuestion[qId] = (lowerCountByQuestion[qId] ?? 0) + 1;
        }
      }
    }

    // Build (studentId, questionId) -> [(choiceId, isCorrect)] for distractors
    final answerIdToQuestionId = <String, String>{};
    for (final a in data.answers) {
      answerIdToQuestionId[a.id] = a.questionId;
    }

    final studentChoices = <String, Map<String, List<(String?, bool)>>>{};
    for (final answer in data.answers) {
      final items = answerItemsByAnswer[answer.id] ?? [];
      final studentId = submissionToStudent[answer.submissionId];
      if (studentId == null) continue;
      for (final item in items) {
        studentChoices
            .putIfAbsent(studentId, () => {})
            .putIfAbsent(answer.questionId, () => [])
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

    // Group choices by question
    final choicesByQuestion = <String, List<ChoiceRow>>{};
    for (final c in data.choices) {
      choicesByQuestion.putIfAbsent(c.questionId, () => []).add(c);
    }

    double totalP = 0.0;
    double totalD = 0.0;
    int retainCount = 0;
    int reviseCount = 0;
    int discardCount = 0;

    final itemAnalysis = <ItemAnalysisModel>[];

    for (final q in data.questions) {
      final maxPoints = q.points;

      final upperSum = upperAvgByQuestion[q.id] ?? 0.0;
      final lowerSum = lowerAvgByQuestion[q.id] ?? 0.0;
      final upperN = upperCountByQuestion[q.id] ?? 0;
      final lowerN = lowerCountByQuestion[q.id] ?? 0;

      final upperAvg = upperN > 0 ? upperSum / upperN : 0.0;
      final lowerAvg = lowerN > 0 ? lowerSum / lowerN : 0.0;

      final p = maxPoints > 0
          ? _computeQuestionAverage(studentQuestionPoints, q.id) / maxPoints
          : 0.0;
      final d = maxPoints > 0
          ? (upperAvg / maxPoints) - (lowerAvg / maxPoints)
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
        final choices = choicesByQuestion[q.id];
        if (choices != null) {
          distractors = [];
          for (final c in choices) {
            final (totalSelected, upperCount, lowerCount) =
                choiceSelections[q.id]?[c.id] ?? (0, 0, 0);
            final totalPercentage = data.submissionCount > 0
                ? (totalSelected / data.submissionCount) * 100.0
                : 0.0;
            final isEffective =
                c.isCorrect ? true : lowerCount > upperCount;

            distractors.add(DistractorAnalysisModel(
              choiceId: c.id,
              choiceText: c.choiceText,
              isCorrect: c.isCorrect,
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

    TestSummaryModel? testSummary;
    final totalItems = itemAnalysis.length;
    if (totalItems > 0) {
      double? kr20;
      final nStudents = data.submissionCount.toDouble();
      final k = totalItems.toDouble();
      if (k > 1.0 && nStudents > 1.0) {
        // Per-item proportion correct across ALL students (binary threshold)
        double pqSum = 0.0;
        for (final q in data.questions) {
          int correct = 0;
          for (final entry in studentQuestionCorrect.entries) {
            if (entry.value[q.id] == true) correct++;
          }
          final pI = correct / nStudents;
          pqSum += pI * (1.0 - pI);
        }

        // Variance of correct-item counts per student
        final studentCorrect = <String, int>{};
        for (final entry in studentQuestionCorrect.entries) {
          studentCorrect[entry.key] =
              entry.value.values.where((v) => v).length;
        }
        final correctCounts = data.submissions
            .map((s) => studentCorrect[s.userId]?.toDouble() ?? 0.0)
            .toList();
        final meanCorrect = correctCounts.reduce((a, b) => a + b) / nStudents;
        final variance = correctCounts
                .map((c) {
                  final d = c - meanCorrect;
                  return d * d;
                })
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

    return (itemAnalysis, testSummary);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static double _computeQuestionAverage(
    Map<String, Map<String, double>> studentQuestionPoints,
    String questionId,
  ) {
    double sum = 0.0;
    int count = 0;
    for (final entry in studentQuestionPoints.entries) {
      final points = entry.value[questionId];
      if (points != null) {
        sum += points;
        count++;
      }
    }
    return count > 0 ? sum / count : 0.0;
  }

  static String _getDifficultyLabel(double p) {
    if (p >= 0.86) return 'Very Easy';
    if (p >= 0.71) return 'Easy';
    if (p >= 0.30) return 'Moderate';
    if (p >= 0.15) return 'Difficult';
    return 'Very Difficult';
  }

  static String _getDiscriminationLabel(double d) {
    if (d >= 0.40) return 'Very Good';
    if (d >= 0.30) return 'Reasonably Good';
    if (d >= 0.20) return 'Marginal';
    return 'Poor';
  }

  static String _getVerdict(double p, double d) {
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
}

class _StudentScore {
  final String studentId;
  final double totalPoints;

  _StudentScore({required this.studentId, required this.totalPoints});
}
