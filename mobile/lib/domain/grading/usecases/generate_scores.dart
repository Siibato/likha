import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/services/score_generation_service.dart';

/// Parameters for generating scores for a class
class GenerateScoresParams {
  final String classId;
  final int gradingPeriodNumber;
  final List<GradeItem>? items;

  const GenerateScoresParams({
    required this.classId,
    required this.gradingPeriodNumber,
    this.items,
  });
}

/// Parameters for generating scores for a specific grade item
class GenerateScoresForGradeItemParams {
  final String gradeItemId;

  const GenerateScoresForGradeItemParams({
    required this.gradeItemId,
  });
}

/// Use case for generating scores from assessment submissions
class GenerateScores {
  final ScoreGenerationService _service;

  GenerateScores(this._service);

  /// Generate scores for all grade items in a class for a specific grading period
  ResultFuture<void> generateScoresForClass(GenerateScoresParams params) async {
    return await _service.generateScoresForClass(
      classId: params.classId,
      gradingPeriodNumber: params.gradingPeriodNumber,
      items: params.items,
    );
  }

  /// Generate scores for a specific grade item
  ResultFuture<void> generateScoresForGradeItem(GenerateScoresForGradeItemParams params) async {
    return await _service.generateScoresForGradeItemById(params.gradeItemId);
  }
}

/// Use case for checking if scores exist for a grade item
class HasScoresForGradeItem {
  final ScoreGenerationService _service;

  HasScoresForGradeItem(this._service);

  ResultFuture<bool> call(String gradeItemId) async {
    return await _service.hasScoresForGradeItem(gradeItemId);
  }
}

/// Use case for getting score summary for a grade item
class GetScoreSummary {
  final ScoreGenerationService _service;

  GetScoreSummary(this._service);

  ResultFuture<Map<String, dynamic>> call(String gradeItemId) async {
    return await _service.getScoreSummary(gradeItemId);
  }
}
