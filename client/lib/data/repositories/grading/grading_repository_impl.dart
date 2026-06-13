import 'package:likha/core/network/server_reachability_service.dart';
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
  final ServerReachabilityService _serverReachabilityService;
  final SyncQueue _syncQueue;

  GradingRepositoryImpl({
    required GradingRemoteDataSource remoteDataSource,
    required GradingLocalDataSource localDataSource,
    required ServerReachabilityService serverReachabilityService,
    required SyncQueue syncQueue,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _serverReachabilityService = serverReachabilityService,
        _syncQueue = syncQueue;

  // ===== Config =====

  @override
  ResultFuture<List<GradeConfig>> getGradingConfig({
    required String classId,
  }) =>
      ops.getGradingConfig(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        classId: classId,
      );

  @override
  ResultVoid setupGrading({
    required String classId,
    required String gradeLevel,
    required String subjectGroup,
    required String schoolYear,
    int? semester,
  }) =>
      ops.setupGrading(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        classId: classId,
        gradeLevel: gradeLevel,
        subjectGroup: subjectGroup,
        schoolYear: schoolYear,
        semester: semester,
      );

  @override
  ResultVoid updateGradingConfig({
    required String classId,
    required List<Map<String, dynamic>> configs,
  }) =>
      ops.updateGradingConfig(
        _localDataSource,
        _syncQueue,
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
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
        component: component,
      );

  @override
  ResultFuture<GradeItem> createGradeItem({
    required String classId,
    required Map<String, dynamic> data,
  }) =>
      ops.createGradeItem(
        _localDataSource,
        _syncQueue,
        classId: classId,
        data: data,
      );

  @override
  ResultVoid updateGradeItem({
    required String id,
    required Map<String, dynamic> data,
  }) =>
      ops.updateGradeItem(
        _localDataSource,
        _syncQueue,
        id: id,
        data: data,
      );

  @override
  ResultVoid deleteGradeItem({required String id}) =>
      ops.deleteGradeItem(
        _localDataSource,
        _syncQueue,
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
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        gradeItemId: gradeItemId,
      );

  @override
  ResultVoid saveScores({
    required String gradeItemId,
    required List<Map<String, dynamic>> scores,
  }) =>
      ops.saveScores(
        _localDataSource,
        gradeItemId: gradeItemId,
        scores: scores,
      );

  @override
  ResultVoid setScoreOverride({
    required String scoreId,
    required double overrideScore,
  }) =>
      ops.setScoreOverride(
        _localDataSource,
        _syncQueue,
        scoreId: scoreId,
        overrideScore: overrideScore,
      );

  @override
  ResultVoid clearScoreOverride({required String scoreId}) =>
      ops.clearScoreOverride(
        _localDataSource,
        _syncQueue,
        scoreId: scoreId,
      );

  // ===== Computed Grades =====

  @override
  ResultFuture<List<PeriodGrade>> getPeriodGrades({
    required String classId,
    required int gradingPeriodNumber,
  }) =>
      ops.getPeriodGrades(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
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
  ResultVoid updateTransmutedGrade({
    required String classId,
    required String studentId,
    required int gradingPeriodNumber,
    required int transmutedGrade,
  }) =>
      ops.updateTransmutedGrade(
        _localDataSource,
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
        _remoteDataSource,
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
      );

  @override
  ResultFuture<List<Map<String, dynamic>>> getFinalGrades({
    required String classId,
  }) =>
      ops.getFinalGrades(
        _remoteDataSource,
        classId: classId,
      );

  // ===== Student =====

  @override
  ResultFuture<List<PeriodGrade>> getMyGrades({
    required String classId,
  }) =>
      ops.getMyGrades(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        classId: classId,
      );

  @override
  ResultFuture<Map<String, dynamic>> getMyGradeDetail({
    required String classId,
    required int gradingPeriodNumber,
  }) =>
      ops.getMyGradeDetail(
        _remoteDataSource,
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
      );

  // ===== General Average =====

  @override
  ResultFuture<GeneralAverageResponse> getGeneralAverages({
    required String classId,
  }) =>
      ops.getGeneralAverages(
        _remoteDataSource,
        classId: classId,
      );

  // ===== SF9/SF10 =====

  @override
  ResultFuture<Sf9Response> getSf9({
    required String classId,
    required String studentId,
  }) =>
      ops.getSf9(
        _remoteDataSource,
        classId: classId,
        studentId: studentId,
      );

  @override
  ResultFuture<Sf9Response> getSf10({
    required String classId,
    required String studentId,
  }) =>
      ops.getSf10(
        _remoteDataSource,
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
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
      );
}
