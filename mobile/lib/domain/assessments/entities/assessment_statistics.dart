import 'package:equatable/equatable.dart';

class AssessmentStatistics extends Equatable {
  final String assessmentId;
  final String title;
  final int totalPoints;
  final int submissionCount;
  final ClassStatistics classStatistics;
  final List<QuestionStatistics> questionStatistics;

  const AssessmentStatistics({
    required this.assessmentId,
    required this.title,
    required this.totalPoints,
    required this.submissionCount,
    required this.classStatistics,
    required this.questionStatistics,
  });

  @override
  List<Object?> get props => [assessmentId, title, submissionCount];
}

class ClassStatistics extends Equatable {
  final double mean;
  final double median;
  final double highest;
  final double lowest;
  final List<ScoreBucket> scoreDistribution;

  const ClassStatistics({
    required this.mean,
    required this.median,
    required this.highest,
    required this.lowest,
    required this.scoreDistribution,
  });

  @override
  List<Object?> get props => [mean, median, highest, lowest];
}

class ScoreBucket extends Equatable {
  final int score;
  final int count;

  const ScoreBucket({required this.score, required this.count});

  @override
  List<Object?> get props => [score, count];
}

class QuestionStatistics extends Equatable {
  final String questionId;
  final String questionText;
  final String questionType;
  final int points;
  final int correctCount;
  final int incorrectCount;
  final double correctPercentage;

  const QuestionStatistics({
    required this.questionId,
    required this.questionText,
    required this.questionType,
    required this.points,
    required this.correctCount,
    required this.incorrectCount,
    required this.correctPercentage,
  });

  @override
  List<Object?> get props => [questionId, correctPercentage];
}
