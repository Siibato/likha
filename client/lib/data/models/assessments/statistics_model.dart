import 'package:likha/domain/assessments/entities/assessment_statistics.dart';

class AssessmentStatisticsModel extends AssessmentStatistics {
  const AssessmentStatisticsModel({
    required super.assessmentId,
    required super.title,
    required super.totalPoints,
    required super.submissionCount,
    required super.classStatistics,
    required super.questionStatistics,
    super.itemAnalysis,
    super.testSummary,
  });

  factory AssessmentStatisticsModel.fromJson(Map<String, dynamic> json) {
    return AssessmentStatisticsModel(
      assessmentId: json['assessment_id'] as String,
      title: json['title'] as String,
      totalPoints: json['total_points'] as int,
      submissionCount: json['submission_count'] as int,
      classStatistics: ClassStatisticsModel.fromJson(
          json['class_statistics'] as Map<String, dynamic>),
      questionStatistics: (json['question_statistics'] as List<dynamic>)
          .map((e) =>
              QuestionStatisticsModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      itemAnalysis: (json['item_analysis'] as List<dynamic>?)
              ?.map((e) =>
                  ItemAnalysisModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      testSummary: json['test_summary'] != null
          ? TestSummaryModel.fromJson(
              json['test_summary'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'assessment_id': assessmentId,
    'title': title,
    'total_points': totalPoints,
    'submission_count': submissionCount,
    'class_statistics': (classStatistics as ClassStatisticsModel).toJson(),
    'question_statistics': (questionStatistics as List<QuestionStatisticsModel>)
        .map((e) => e.toJson())
        .toList(),
    'item_analysis': itemAnalysis
        .map((e) => (e as ItemAnalysisModel).toJson())
        .toList(),
    if (testSummary != null)
      'test_summary': (testSummary as TestSummaryModel).toJson(),
  };
}

class ClassStatisticsModel extends ClassStatistics {
  const ClassStatisticsModel({
    required super.mean,
    required super.median,
    required super.highest,
    required super.lowest,
    required super.scoreDistribution,
  });

  factory ClassStatisticsModel.fromJson(Map<String, dynamic> json) {
    return ClassStatisticsModel(
      mean: (json['mean'] as num).toDouble(),
      median: (json['median'] as num).toDouble(),
      highest: (json['highest'] as num).toDouble(),
      lowest: (json['lowest'] as num).toDouble(),
      scoreDistribution: (json['score_distribution'] as List<dynamic>)
          .map((e) => ScoreBucketModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'mean': mean,
    'median': median,
    'highest': highest,
    'lowest': lowest,
    'score_distribution': (scoreDistribution as List<ScoreBucketModel>)
        .map((e) => e.toJson())
        .toList(),
  };
}

class ScoreBucketModel extends ScoreBucket {
  const ScoreBucketModel({required super.score, required super.count});

  factory ScoreBucketModel.fromJson(Map<String, dynamic> json) {
    return ScoreBucketModel(
      score: json['score'] as int,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'score': score,
    'count': count,
  };
}

class QuestionStatisticsModel extends QuestionStatistics {
  const QuestionStatisticsModel({
    required super.questionId,
    required super.questionText,
    required super.questionType,
    required super.points,
    required super.correctCount,
    required super.incorrectCount,
    required super.correctPercentage,
  });

  factory QuestionStatisticsModel.fromJson(Map<String, dynamic> json) {
    return QuestionStatisticsModel(
      questionId: json['question_id'] as String,
      questionText: json['question_text'] as String,
      questionType: json['question_type'] as String,
      points: json['points'] as int,
      correctCount: json['correct_count'] as int,
      incorrectCount: json['incorrect_count'] as int,
      correctPercentage: (json['correct_percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'question_text': questionText,
    'question_type': questionType,
    'points': points,
    'correct_count': correctCount,
    'incorrect_count': incorrectCount,
    'correct_percentage': correctPercentage,
  };
}

class ItemAnalysisModel extends ItemAnalysis {
  const ItemAnalysisModel({
    required super.questionId,
    required super.questionText,
    required super.questionType,
    required super.points,
    required super.difficultyIndex,
    required super.difficultyLabel,
    required super.discriminationIndex,
    required super.discriminationLabel,
    required super.verdict,
    super.distractors,
  });

  factory ItemAnalysisModel.fromJson(Map<String, dynamic> json) {
    return ItemAnalysisModel(
      questionId: json['question_id'] as String,
      questionText: json['question_text'] as String,
      questionType: json['question_type'] as String,
      points: json['points'] as int,
      difficultyIndex: (json['difficulty_index'] as num).toDouble(),
      difficultyLabel: json['difficulty_label'] as String,
      discriminationIndex: (json['discrimination_index'] as num).toDouble(),
      discriminationLabel: json['discrimination_label'] as String,
      verdict: json['verdict'] as String,
      distractors: (json['distractors'] as List<dynamic>?)
          ?.map((e) =>
              DistractorAnalysisModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'question_text': questionText,
    'question_type': questionType,
    'points': points,
    'difficulty_index': difficultyIndex,
    'difficulty_label': difficultyLabel,
    'discrimination_index': discriminationIndex,
    'discrimination_label': discriminationLabel,
    'verdict': verdict,
    if (distractors != null)
      'distractors': distractors!
          .map((e) => (e as DistractorAnalysisModel).toJson())
          .toList(),
  };
}

class DistractorAnalysisModel extends DistractorAnalysis {
  const DistractorAnalysisModel({
    required super.choiceId,
    required super.choiceText,
    required super.isCorrect,
    required super.upperCount,
    required super.lowerCount,
    required super.totalPercentage,
    required super.isEffective,
  });

  factory DistractorAnalysisModel.fromJson(Map<String, dynamic> json) {
    return DistractorAnalysisModel(
      choiceId: json['choice_id'] as String,
      choiceText: json['choice_text'] as String,
      isCorrect: json['is_correct'] as bool,
      upperCount: json['upper_count'] as int,
      lowerCount: json['lower_count'] as int,
      totalPercentage: (json['total_percentage'] as num).toDouble(),
      isEffective: json['is_effective'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'choice_id': choiceId,
    'choice_text': choiceText,
    'is_correct': isCorrect,
    'upper_count': upperCount,
    'lower_count': lowerCount,
    'total_percentage': totalPercentage,
    'is_effective': isEffective,
  };
}

class TestSummaryModel extends TestSummary {
  const TestSummaryModel({
    required super.meanDifficulty,
    required super.meanDiscrimination,
    required super.retainCount,
    required super.reviseCount,
    required super.discardCount,
    required super.totalItemsAnalyzed,
    required super.upperGroupSize,
    required super.lowerGroupSize,
  });

  factory TestSummaryModel.fromJson(Map<String, dynamic> json) {
    return TestSummaryModel(
      meanDifficulty: (json['mean_difficulty'] as num).toDouble(),
      meanDiscrimination: (json['mean_discrimination'] as num).toDouble(),
      retainCount: json['retain_count'] as int,
      reviseCount: json['revise_count'] as int,
      discardCount: json['discard_count'] as int,
      totalItemsAnalyzed: json['total_items_analyzed'] as int,
      upperGroupSize: json['upper_group_size'] as int,
      lowerGroupSize: json['lower_group_size'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'mean_difficulty': meanDifficulty,
    'mean_discrimination': meanDiscrimination,
    'retain_count': retainCount,
    'revise_count': reviseCount,
    'discard_count': discardCount,
    'total_items_analyzed': totalItemsAnalyzed,
    'upper_group_size': upperGroupSize,
    'lower_group_size': lowerGroupSize,
  };
}
