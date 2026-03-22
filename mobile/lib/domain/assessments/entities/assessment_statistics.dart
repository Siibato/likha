import 'package:equatable/equatable.dart';

class AssessmentStatistics extends Equatable {
  final String assessmentId;
  final String title;
  final int totalPoints;
  final int submissionCount;
  final ClassStatistics classStatistics;
  final List<QuestionStatistics> questionStatistics;
  final List<ItemAnalysis> itemAnalysis;
  final TestSummary? testSummary;

  const AssessmentStatistics({
    required this.assessmentId,
    required this.title,
    required this.totalPoints,
    required this.submissionCount,
    required this.classStatistics,
    required this.questionStatistics,
    this.itemAnalysis = const [],
    this.testSummary,
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

class ItemAnalysis extends Equatable {
  final String questionId;
  final String questionText;
  final String questionType;
  final int points;
  final double difficultyIndex;
  final String difficultyLabel;
  final double discriminationIndex;
  final String discriminationLabel;
  final String verdict;
  final List<DistractorAnalysis>? distractors;

  const ItemAnalysis({
    required this.questionId,
    required this.questionText,
    required this.questionType,
    required this.points,
    required this.difficultyIndex,
    required this.difficultyLabel,
    required this.discriminationIndex,
    required this.discriminationLabel,
    required this.verdict,
    this.distractors,
  });

  @override
  List<Object?> get props => [questionId, verdict];
}

class DistractorAnalysis extends Equatable {
  final String choiceId;
  final String choiceText;
  final bool isCorrect;
  final int upperCount;
  final int lowerCount;
  final double totalPercentage;
  final bool isEffective;

  const DistractorAnalysis({
    required this.choiceId,
    required this.choiceText,
    required this.isCorrect,
    required this.upperCount,
    required this.lowerCount,
    required this.totalPercentage,
    required this.isEffective,
  });

  @override
  List<Object?> get props => [choiceId, isCorrect];
}

class TestSummary extends Equatable {
  final double meanDifficulty;
  final double meanDiscrimination;
  final int retainCount;
  final int reviseCount;
  final int discardCount;
  final int totalItemsAnalyzed;
  final int upperGroupSize;
  final int lowerGroupSize;

  const TestSummary({
    required this.meanDifficulty,
    required this.meanDiscrimination,
    required this.retainCount,
    required this.reviseCount,
    required this.discardCount,
    required this.totalItemsAnalyzed,
    required this.upperGroupSize,
    required this.lowerGroupSize,
  });

  @override
  List<Object?> get props => [totalItemsAnalyzed, meanDifficulty];
}
