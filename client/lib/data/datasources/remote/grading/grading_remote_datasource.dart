import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/grading/grade_config_model.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';
import 'package:likha/data/models/grading/grade_score_model.dart';
import 'package:likha/data/models/grading/period_grade_model.dart';
import 'package:likha/data/models/grading/general_average_model.dart';
import 'package:likha/data/models/grading/sf9_model.dart';
import 'package:likha/data/datasources/remote/grading/operations/grading.dart' as ops;

abstract class GradingRemoteDataSource {
  // Config
  Future<List<GradeConfigModel>> getGradingConfig({required String classId});
  Future<void> setupGrading({
    required String classId,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  });
  Future<void> updateGradingConfig({
    required String classId,
    required List<Map<String, dynamic>> configs,
    String? idempotencyKey,
  });

  // Unified
  Future<Map<String, dynamic>> getClassGrades({
    required String classId,
    required int gradingPeriodNumber,
  });

  // Grade Items
  Future<List<GradeItemModel>> getGradeItems({
    required String classId,
    required int gradingPeriodNumber,
    String? component,
  });
  Future<GradeItemModel> createGradeItem({
    required String classId,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  });
  Future<void> updateGradeItem({
    required String id,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  });
  Future<void> deleteGradeItem({required String id, String? idempotencyKey});

  // Scores
  Future<List<GradeScoreModel>> getScoresByItem({required String gradeItemId});
  Future<void> saveScores({
    required String gradeItemId,
    required List<Map<String, dynamic>> scores,
    String? idempotencyKey,
  });
  Future<void> setScoreOverride({
    required String scoreId,
    required double overrideScore,
    String? idempotencyKey,
  });
  Future<void> clearScoreOverride({required String scoreId, String? idempotencyKey});

  // Computed Grades
  Future<List<PeriodGradeModel>> getPeriodGrades({
    required String classId,
    required int gradingPeriodNumber,
  });
  Future<void> computeGrades({
    required String classId,
    required int gradingPeriodNumber,
  });
  Future<List<Map<String, dynamic>>> getGradeSummary({
    required String classId,
    required int gradingPeriodNumber,
  });
  Future<List<Map<String, dynamic>>> getFinalGrades({required String classId});

  // Student
  Future<List<PeriodGradeModel>> getMyGrades({required String classId});
  Future<Map<String, dynamic>> getMyGradeDetail({
    required String classId,
    required int gradingPeriodNumber,
  });

  // Presets
  Future<Map<String, dynamic>> getDepEdPresets();

  // General Average
  Future<GeneralAverageResponseModel> getGeneralAverages({
    required String classId,
  });

  // SF9/SF10
  Future<Sf9ResponseModel> getSf9({
    required String classId,
    required String studentId,
  });
  Future<Sf9ResponseModel> getSf10({
    required String classId,
    required String studentId,
  });
}

class GradingRemoteDataSourceImpl implements GradingRemoteDataSource {
  final DioClient _dioClient;

  GradingRemoteDataSourceImpl(this._dioClient);

  // ===== Config =====

  @override
  Future<List<GradeConfigModel>> getGradingConfig({
    required String classId,
  }) =>
      ops.getGradingConfig(
        _dioClient,
        classId: classId,
      );

  @override
  Future<void> setupGrading({
    required String classId,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  }) =>
      ops.setupGrading(
        _dioClient,
        classId: classId,
        data: data,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> updateGradingConfig({
    required String classId,
    required List<Map<String, dynamic>> configs,
    String? idempotencyKey,
  }) =>
      ops.updateGradingConfig(
        _dioClient,
        classId: classId,
        configs: configs,
        idempotencyKey: idempotencyKey,
      );

  // ===== Unified =====

  @override
  Future<Map<String, dynamic>> getClassGrades({
    required String classId,
    required int gradingPeriodNumber,
  }) =>
      ops.getClassGrades(
        _dioClient,
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
      );

  // ===== Grade Items =====

  @override
  Future<List<GradeItemModel>> getGradeItems({
    required String classId,
    required int gradingPeriodNumber,
    String? component,
  }) =>
      ops.getGradeItems(
        _dioClient,
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
        component: component,
      );

  @override
  Future<GradeItemModel> createGradeItem({
    required String classId,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  }) =>
      ops.createGradeItem(
        _dioClient,
        classId: classId,
        data: data,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> updateGradeItem({
    required String id,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  }) =>
      ops.updateGradeItem(
        _dioClient,
        id: id,
        data: data,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> deleteGradeItem({required String id, String? idempotencyKey}) =>
      ops.deleteGradeItem(
        _dioClient,
        id: id,
        idempotencyKey: idempotencyKey,
      );

  // ===== Scores =====

  @override
  Future<List<GradeScoreModel>> getScoresByItem({
    required String gradeItemId,
  }) =>
      ops.getScoresByItem(
        _dioClient,
        gradeItemId: gradeItemId,
      );

  @override
  Future<void> saveScores({
    required String gradeItemId,
    required List<Map<String, dynamic>> scores,
    String? idempotencyKey,
  }) =>
      ops.saveScores(
        _dioClient,
        gradeItemId: gradeItemId,
        scores: scores,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> setScoreOverride({
    required String scoreId,
    required double overrideScore,
    String? idempotencyKey,
  }) =>
      ops.setScoreOverride(
        _dioClient,
        scoreId: scoreId,
        overrideScore: overrideScore,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> clearScoreOverride({required String scoreId, String? idempotencyKey}) =>
      ops.clearScoreOverride(
        _dioClient,
        scoreId: scoreId,
        idempotencyKey: idempotencyKey,
      );

  // ===== Computed Grades =====

  @override
  Future<List<PeriodGradeModel>> getPeriodGrades({
    required String classId,
    required int gradingPeriodNumber,
  }) =>
      ops.getPeriodGrades(
        _dioClient,
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
      );

  @override
  Future<void> computeGrades({
    required String classId,
    required int gradingPeriodNumber,
  }) =>
      ops.computeGrades(
        _dioClient,
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
      );

  @override
  Future<List<Map<String, dynamic>>> getGradeSummary({
    required String classId,
    required int gradingPeriodNumber,
  }) =>
      ops.getGradeSummary(
        _dioClient,
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
      );

  @override
  Future<List<Map<String, dynamic>>> getFinalGrades({
    required String classId,
  }) =>
      ops.getFinalGrades(
        _dioClient,
        classId: classId,
      );

  // ===== Student =====

  @override
  Future<List<PeriodGradeModel>> getMyGrades({
    required String classId,
  }) =>
      ops.getMyGrades(
        _dioClient,
        classId: classId,
      );

  @override
  Future<Map<String, dynamic>> getMyGradeDetail({
    required String classId,
    required int gradingPeriodNumber,
  }) =>
      ops.getMyGradeDetail(
        _dioClient,
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
      );

  // ===== Presets =====

  @override
  Future<Map<String, dynamic>> getDepEdPresets() =>
      ops.getDepEdPresets(
        _dioClient,
      );

  // ===== General Average =====

  @override
  Future<GeneralAverageResponseModel> getGeneralAverages({
    required String classId,
  }) =>
      ops.getGeneralAverages(
        _dioClient,
        classId: classId,
      );

  // ===== SF9/SF10 =====

  @override
  Future<Sf9ResponseModel> getSf9({
    required String classId,
    required String studentId,
  }) =>
      ops.getSf9(
        _dioClient,
        classId: classId,
        studentId: studentId,
      );

  @override
  Future<Sf9ResponseModel> getSf10({
    required String classId,
    required String studentId,
  }) =>
      ops.getSf10(
        _dioClient,
        classId: classId,
        studentId: studentId,
      );
}
