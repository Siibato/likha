import 'package:likha/domain/assessments/entities/assessment_statistics.dart';

class AssessmentStatisticsModel extends AssessmentStatistics {
  const AssessmentStatisticsModel({
    required super.assessmentId,
    required super.title,
    required super.totalPoints,
    required super.submissionCount,
    required super.classStatistics,
    required super.questionStatistics,
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
