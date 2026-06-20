import 'package:flutter_test/flutter_test.dart';
import 'package:likha/data/datasources/local/assessments/operations/statistics_computer.dart';
import 'package:likha/data/datasources/local/assessments/operations/statistics_data_fetcher.dart';

void main() {
  group('StatisticsComputer', () {
    test('returns empty stats when no submissions', () {
      const data = StatisticsRawData(
        assessmentId: 'a1',
        title: 'Test',
        totalPoints: 20,
        submissions: [],
        questions: [
          QuestionRow(
            id: 'q1',
            questionType: 'multiple_choice',
            questionText: 'Q1',
            points: 5,
            isMultiSelect: false,
          ),
        ],
        answers: [],
        answerItems: [],
        choices: [],
      );

      final stats = StatisticsComputer.compute(data);

      expect(stats.submissionCount, 0);
      expect(stats.questionStatistics.length, 1);
      expect(stats.questionStatistics.first.averagePoints, 0.0);
      expect(stats.itemAnalysis, isEmpty);
    });

    test('computes average points and percentage correctly', () {
      const data = StatisticsRawData(
        assessmentId: 'a1',
        title: 'Test',
        totalPoints: 20,
        submissions: [
          SubmissionRow(id: 's1', userId: 'u1', totalPoints: 15.0),
          SubmissionRow(id: 's2', userId: 'u2', totalPoints: 10.0),
        ],
        questions: [
          QuestionRow(
            id: 'q1',
            questionType: 'multiple_choice',
            questionText: 'Q1',
            points: 5,
            isMultiSelect: false,
          ),
        ],
        answers: [
          AnswerRow(id: 'a1', submissionId: 's1', questionId: 'q1', points: 5.0),
          AnswerRow(id: 'a2', submissionId: 's2', questionId: 'q1', points: 3.0),
        ],
        answerItems: [
          AnswerItemRow(submissionAnswerId: 'a1', choiceId: 'c1', isCorrect: true),
          AnswerItemRow(submissionAnswerId: 'a2', choiceId: 'c2', isCorrect: false),
        ],
        choices: [
          ChoiceRow(id: 'c1', questionId: 'q1', choiceText: 'A', isCorrect: true),
          ChoiceRow(id: 'c2', questionId: 'q1', choiceText: 'B', isCorrect: false),
        ],
      );

      final stats = StatisticsComputer.compute(data);

      expect(stats.submissionCount, 2);
      expect(stats.questionStatistics.length, 1);

      final qStats = stats.questionStatistics.first;
      expect(qStats.averagePoints, closeTo(4.0, 0.01)); // (5 + 3) / 2
      expect(qStats.averagePercentage, closeTo(80.0, 0.01)); // 4/5 * 100
    });

    test('difficulty index equals average / max (0.7 for avg 14/20)', () {
      // Build data so one question has average 14 out of 20 points
      final data = _buildDataWithQuestionAverage(
        maxPoints: 20,
        studentPoints: [20.0, 14.0, 14.0, 14.0, 14.0, 14.0, 14.0, 14.0, 14.0, 14.0],
      );

      final stats = StatisticsComputer.compute(data);

      // Need >= 10 submissions for item analysis
      expect(stats.itemAnalysis, isNotEmpty);
      final item = stats.itemAnalysis.firstWhere((i) => i.questionId == 'q_essay');
      // Average = (20 + 9*14) / 10 = 146/10 = 14.6
      // Difficulty = 14.6 / 20 = 0.73
      expect(item.difficultyIndex, closeTo(0.73, 0.01));
      expect(item.difficultyLabel, 'Easy'); // >= 0.71
    });

    test('returns null when data is incomplete (no answers)', () {
      const data = StatisticsRawData(
        assessmentId: 'a1',
        title: 'Test',
        totalPoints: 20,
        submissions: [
          SubmissionRow(id: 's1', userId: 'u1', totalPoints: 10.0),
        ],
        questions: [
          QuestionRow(
            id: 'q1',
            questionType: 'multiple_choice',
            questionText: 'Q1',
            points: 5,
            isMultiSelect: false,
          ),
        ],
        answers: [], // No answers despite having a submission
        answerItems: [],
        choices: [],
      );

      expect(data.isComplete, isFalse);
    });

    test('data is complete when all answers have 0 points', () {
      const data = StatisticsRawData(
        assessmentId: 'a1',
        title: 'Test',
        totalPoints: 20,
        submissions: [
          SubmissionRow(id: 's1', userId: 'u1', totalPoints: 0.0),
        ],
        questions: [
          QuestionRow(
            id: 'q1',
            questionType: 'multiple_choice',
            questionText: 'Q1',
            points: 5,
            isMultiSelect: false,
          ),
        ],
        answers: [
          AnswerRow(id: 'a1', submissionId: 's1', questionId: 'q1', points: 0.0),
        ],
        answerItems: [],
        choices: [],
      );

      expect(data.isComplete, isTrue);
    });

    test('data is incomplete when all answers have null points (ungraded draft)', () {
      const data = StatisticsRawData(
        assessmentId: 'a1',
        title: 'Test',
        totalPoints: 20,
        submissions: [
          SubmissionRow(id: 's1', userId: 'u1', totalPoints: 0.0),
        ],
        questions: [
          QuestionRow(
            id: 'q1',
            questionType: 'multiple_choice',
            questionText: 'Q1',
            points: 5,
            isMultiSelect: false,
          ),
        ],
        answers: [
          AnswerRow(id: 'a1', submissionId: 's1', questionId: 'q1', points: null),
        ],
        answerItems: [
          AnswerItemRow(submissionAnswerId: 'a1', choiceId: 'c1', isCorrect: false),
        ],
        choices: [
          ChoiceRow(id: 'c1', questionId: 'q1', choiceText: 'A', isCorrect: true),
        ],
      );

      expect(data.isComplete, isFalse);
    });
  });
}

/// Helper to construct raw data with 10 submissions and one essay question.
StatisticsRawData _buildDataWithQuestionAverage({
  required int maxPoints,
  required List<double> studentPoints,
}) {
  final submissions = <SubmissionRow>[];
  final answers = <AnswerRow>[];
  final answerItems = <AnswerItemRow>[];

  for (var i = 0; i < studentPoints.length; i++) {
    final sid = 's$i';
    final uid = 'u$i';
    final points = studentPoints[i];
    submissions.add(SubmissionRow(id: sid, userId: uid, totalPoints: points));
    answers.add(
      AnswerRow(
        id: 'a$i',
        submissionId: sid,
        questionId: 'q_essay',
        points: points,
      ),
    );
  }

  return StatisticsRawData(
    assessmentId: 'a1',
    title: 'Essay Test',
    totalPoints: maxPoints,
    submissions: submissions,
    questions: [
      QuestionRow(
        id: 'q_essay',
        questionType: 'essay',
        questionText: 'Essay Q',
        points: maxPoints,
        isMultiSelect: false,
      ),
    ],
    answers: answers,
    answerItems: answerItems,
    choices: [],
  );
}
