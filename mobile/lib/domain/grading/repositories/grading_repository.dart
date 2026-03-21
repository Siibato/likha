import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/domain/grading/entities/quarterly_grade.dart';

abstract class GradingRepository {
  // Config
  ResultFuture<List<GradeConfig>> getGradingConfig({required String classId});

  ResultVoid setupGrading({
    required String classId,
    required String gradeLevel,
    required String subjectGroup,
    required String schoolYear,
    int? semester,
  });

  ResultVoid updateGradingConfig({
    required String classId,
    required List<Map<String, dynamic>> configs,
  });

  // Grade Items
  ResultFuture<List<GradeItem>> getGradeItems({
    required String classId,
    required int quarter,
    String? component,
  });

  ResultFuture<GradeItem> createGradeItem({
    required String classId,
    required Map<String, dynamic> data,
  });

  ResultVoid updateGradeItem({
    required String id,
    required Map<String, dynamic> data,
  });

  ResultVoid deleteGradeItem({required String id});

  // Scores
  ResultFuture<List<GradeScore>> getScoresByItem({
    required String gradeItemId,
  });

  ResultVoid saveScores({
    required String gradeItemId,
    required List<Map<String, dynamic>> scores,
  });

  ResultVoid setScoreOverride({
    required String scoreId,
    required double overrideScore,
  });

  ResultVoid clearScoreOverride({required String scoreId});

  // Computed Grades
  ResultFuture<List<QuarterlyGrade>> getQuarterlyGrades({
    required String classId,
    required int quarter,
  });

  ResultVoid computeGrades({
    required String classId,
    required int quarter,
  });

  ResultFuture<List<Map<String, dynamic>>> getGradeSummary({
    required String classId,
    required int quarter,
  });

  ResultFuture<List<Map<String, dynamic>>> getFinalGrades({
    required String classId,
  });

  // Student
  ResultFuture<List<QuarterlyGrade>> getMyGrades({required String classId});

  ResultFuture<Map<String, dynamic>> getMyGradeDetail({
    required String classId,
    required int quarter,
  });
}
