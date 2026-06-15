import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/domain/grading/entities/period_grade.dart';
import 'package:likha/domain/grading/entities/general_average.dart';
import 'package:likha/domain/grading/entities/sf9.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';
import 'operations/grading.dart' as ops;

class GradingRepositoryImpl implements GradingRepository {
  final GradingRemoteDataSource _remoteDataSource;
  final GradingLocalDataSource _localDataSource;
  final SyncQueue _syncQueue;
  final DataEventBus _dataEventBus;

  GradingRepositoryImpl({
    required GradingRemoteDataSource remoteDataSource,
    required GradingLocalDataSource localDataSource,
    required SyncQueue syncQueue,
    required DataEventBus dataEventBus,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _syncQueue = syncQueue,
        _dataEventBus = dataEventBus;

  // ===== Config =====

  @override
  ResultFuture<List<GradeConfig>> getGradingConfig({
    required String classId,
  }) =>
      ops.getGradingConfig(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        classId: classId,
      );

  @override
  ResultFuture<MutationResult<List<GradeConfig>>> setupGrading({
    required String classId,
    required String gradeLevel,
    required String subjectGroup,
    required String schoolYear,
    int? semester,
  }) =>
      ops.setupGrading(
        _localDataSource,
        _syncQueue,
        _remoteDataSource,
        classId: classId,
        gradeLevel: gradeLevel,
        subjectGroup: subjectGroup,
        schoolYear: schoolYear,
        semester: semester,
      );

  @override
  ResultFuture<MutationResult<void>> updateGradingConfig({
    required String classId,
    required List<Map<String, dynamic>> configs,
  }) =>
      ops.updateGradingConfig(
        _localDataSource,
        _syncQueue,
        _remoteDataSource,
        classId: classId,
        configs: configs,
      );

  // ===== Grade Items =====

  @override
  ResultFuture<List<GradeItem>> getGradeItems({
    required String classId,
    required int gradingPeriodNumber,
    String? component,
  }) =>
      ops.getGradeItems(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
        component: component,
      );

  @override
  ResultFuture<MutationResult<GradeItem>> createGradeItem({
    required String classId,
    required Map<String, dynamic> data,
  }) =>
      ops.createGradeItem(
        _localDataSource,
        _syncQueue,
        _remoteDataSource,
        classId: classId,
        data: data,
      );

  @override
  ResultFuture<MutationResult<void>> updateGradeItem({
    required String id,
    required Map<String, dynamic> data,
  }) =>
      ops.updateGradeItem(
        _localDataSource,
        _syncQueue,
        _remoteDataSource,
        id: id,
        data: data,
      );

  @override
  ResultFuture<MutationResult<void>> deleteGradeItem({required String id}) =>
      ops.deleteGradeItem(
        _localDataSource,
        _syncQueue,
        _remoteDataSource,
        id: id,
      );

  @override
  ResultFuture<GradeItem?> findGradeItemBySourceId(String sourceId) =>
      ops.findGradeItemBySourceId(
        _localDataSource,
        sourceId: sourceId,
      );

  // ===== Scores =====

  @override
  ResultFuture<List<GradeScore>> getScoresByItem({
    required String gradeItemId,
  }) =>
      ops.getScoresByItem(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        gradeItemId: gradeItemId,
      );

  @override
  ResultFuture<MutationResult<void>> saveScores({
    required String gradeItemId,
    required List<Map<String, dynamic>> scores,
  }) =>
      ops.saveScores(
        _localDataSource,
        _syncQueue,
        _remoteDataSource,
        gradeItemId: gradeItemId,
        scores: scores,
      );

  @override
  ResultFuture<MutationResult<void>> setScoreOverride({
    required String scoreId,
    required double overrideScore,
  }) =>
      ops.setScoreOverride(
        _localDataSource,
        _syncQueue,
        _remoteDataSource,
        scoreId: scoreId,
        overrideScore: overrideScore,
      );

  @override
  ResultFuture<MutationResult<void>> clearScoreOverride({required String scoreId}) =>
      ops.clearScoreOverride(
        _localDataSource,
        _syncQueue,
        _remoteDataSource,
        scoreId: scoreId,
      );

  // ===== Computed Grades =====

  @override
  ResultFuture<List<PeriodGrade>> getPeriodGrades({
    required String classId,
    required int gradingPeriodNumber,
  }) =>
      ops.getPeriodGrades(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
      );

  @override
  ResultVoid computeGrades({
    required String classId,
    required int gradingPeriodNumber,
  }) =>
      ops.computeGrades(
        _remoteDataSource,
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
      );

  @override
  ResultFuture<MutationResult<void>> updateTransmutedGrade({
    required String classId,
    required String studentId,
    required int gradingPeriodNumber,
    required int transmutedGrade,
  }) =>
      ops.updateTransmutedGrade(
        _localDataSource,
        _syncQueue,
        classId: classId,
        studentId: studentId,
        gradingPeriodNumber: gradingPeriodNumber,
        transmutedGrade: transmutedGrade,
      );

  @override
  ResultFuture<List<Map<String, dynamic>>> getGradeSummary({
    required String classId,
    required int gradingPeriodNumber,
  }) =>
      ops.getGradeSummary(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
      );

  @override
  ResultFuture<List<Map<String, dynamic>>> getFinalGrades({
    required String classId,
  }) =>
      ops.getFinalGrades(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        classId: classId,
      );

  // ===== Student =====

  @override
  ResultFuture<List<PeriodGrade>> getMyGrades({
    required String classId,
  }) =>
      ops.getMyGrades(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        classId: classId,
      );

  @override
  ResultFuture<Map<String, dynamic>> getMyGradeDetail({
    required String classId,
    required int gradingPeriodNumber,
  }) =>
      ops.getMyGradeDetail(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
      );

  // ===== General Average =====

  @override
  ResultFuture<GeneralAverageResponse> getGeneralAverages({
    required String classId,
  }) =>
      ops.getGeneralAverages(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        classId: classId,
      );

  // ===== SF9/SF10 =====

  @override
  ResultFuture<Sf9Response> getSf9({
    required String classId,
    required String studentId,
  }) =>
      ops.getSf9(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        classId: classId,
        studentId: studentId,
      );

  @override
  ResultFuture<Sf9Response> getSf10({
    required String classId,
    required String studentId,
  }) =>
      ops.getSf10(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        classId: classId,
        studentId: studentId,
      );

  // ===== Batch Operations =====

  @override
  ResultFuture<Map<String, dynamic>> getGradeDataBatch({
    required String classId,
    required int gradingPeriodNumber,
  }) =>
      ops.getGradeDataBatch(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
      );
}
