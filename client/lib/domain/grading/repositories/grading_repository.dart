import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/entities/class_grades.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/domain/grading/entities/period_grade.dart';
import 'package:likha/domain/grading/entities/general_average.dart';
import 'package:likha/domain/grading/entities/sf9.dart';

abstract class GradingRepository {
  // Config
  ResultFuture<List<GradeConfig>> getGradingConfig({required String classId});

  ResultFuture<MutationResult<List<GradeConfig>>> setupGrading({
    required String classId,
    required String gradeLevel,
    required String subjectGroup,
    required String schoolYear,
    int? semester,
  });

  ResultFuture<MutationResult<void>> updateGradingConfig({
    required String classId,
    required List<Map<String, dynamic>> configs,
  });

  // Grade Items
  ResultFuture<List<GradeItem>> getGradeItems({
    required String classId,
    required int termNumber,
    String? component,
  });

  ResultFuture<MutationResult<GradeItem>> createGradeItem({
    required String classId,
    required Map<String, dynamic> data,
  });

  ResultFuture<MutationResult<void>> updateGradeItem({
    required String id,
    required Map<String, dynamic> data,
  });

  ResultFuture<MutationResult<void>> deleteGradeItem({required String id});

  ResultFuture<GradeItem?> findGradeItemBySourceId(String sourceId);

  // Scores
  ResultFuture<List<GradeScore>> getScoresByItem({
    required String gradeItemId,
  });

  ResultFuture<MutationResult<void>> saveScores({
    required String gradeItemId,
    required List<Map<String, dynamic>> scores,
  });

  ResultFuture<MutationResult<void>> setScoreOverride({
    required String scoreId,
    required double overrideScore,
  });

  ResultFuture<MutationResult<void>> clearScoreOverride({required String scoreId});

  // Computed Grades
  ResultFuture<List<PeriodGrade>> getTermGrades({
    required String classId,
    required int termNumber,
  });

  ResultVoid computeGrades({
    required String classId,
    required int termNumber,
  });

  ResultFuture<MutationResult<void>> updateTransmutedGrade({
    required String classId,
    required String studentId,
    required int termNumber,
    required int transmutedGrade,
  });

  ResultFuture<List<Map<String, dynamic>>> getGradeSummary({
    required String classId,
    required int termNumber,
  });

  ResultFuture<List<Map<String, dynamic>>> getFinalGrades({
    required String classId,
  });

  // Student
  ResultFuture<List<PeriodGrade>> getMyGrades({required String classId});

  ResultFuture<Map<String, dynamic>> getMyGradeDetail({
    required String classId,
    required int termNumber,
  });

  // General Average
  ResultFuture<GeneralAverageResponse> getGeneralAverages({
    required String classId,
  });

  // SF9/SF10
  ResultFuture<Sf9Response> getSf9({
    required String classId,
    required String studentId,
    bool skipBackgroundRefresh = false,
  });

  ResultFuture<Sf9Response> getSf10({
    required String classId,
    required String studentId,
    bool skipBackgroundRefresh = false,
  });

  // Batch Operations
  ResultFuture<Map<String, dynamic>> getGradeDataBatch({
    required String classId,
    required int termNumber,
  });

  // Unified read
  ResultFuture<ClassGrades> getClassGrades({
    required String classId,
    required int termNumber,
    bool skipBackgroundRefresh = false,
  });
}
