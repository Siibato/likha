import 'package:dartz/dartz.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/domain/grading/entities/class_grades.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/domain/grading/entities/term_grade.dart';
import 'package:likha/domain/grading/entities/general_average.dart';
import 'package:likha/domain/grading/entities/sf9.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';
import 'package:likha/domain/student_records/repositories/student_records_repository.dart';
import 'package:likha/domain/student_records/entities/sf10_response.dart';
import 'operations/grading.dart' as ops;

class GradingRepositoryImpl implements GradingRepository {
  final GradingRemoteDataSource _remoteDataSource;
  final GradingLocalDataSource _localDataSource;
  final SyncQueue _syncQueue;
  final DataEventBus _dataEventBus;
  final StudentRecordsRepository? _studentRecordsRepository;

  GradingRepositoryImpl({
    required GradingRemoteDataSource remoteDataSource,
    required GradingLocalDataSource localDataSource,
    required SyncQueue syncQueue,
    required DataEventBus dataEventBus,
    StudentRecordsRepository? studentRecordsRepository,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _syncQueue = syncQueue,
        _dataEventBus = dataEventBus,
        _studentRecordsRepository = studentRecordsRepository;

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
        classId: classId,
        configs: configs,
      );

  // ===== Grade Items =====

  @override
  ResultFuture<List<GradeItem>> getGradeItems({
    required String classId,
    required int termNumber,
    String? component,
  }) =>
      ops.getGradeItems(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        classId: classId,
        termNumber: termNumber,
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
        _dataEventBus,
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
        _dataEventBus,
        id: id,
        data: data,
      );

  @override
  ResultFuture<MutationResult<void>> deleteGradeItem({required String id}) =>
      ops.deleteGradeItem(
        _localDataSource,
        _syncQueue,
        _dataEventBus,
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
        scoreId: scoreId,
        overrideScore: overrideScore,
      );

  @override
  ResultFuture<MutationResult<void>> clearScoreOverride({required String scoreId}) =>
      ops.clearScoreOverride(
        _localDataSource,
        _syncQueue,
        scoreId: scoreId,
      );

  // ===== Computed Grades =====

  @override
  ResultFuture<List<TermGrade>> getTermGrades({
    required String classId,
    required int termNumber,
  }) =>
      ops.getTermGrades(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        classId: classId,
        termNumber: termNumber,
      );

  @override
  ResultVoid computeGrades({
    required String classId,
    required int termNumber,
  }) =>
      ops.computeGrades(
        _remoteDataSource,
        classId: classId,
        termNumber: termNumber,
      );

  @override
  ResultFuture<MutationResult<void>> updateTransmutedGrade({
    required String classId,
    required String studentId,
    required int termNumber,
    required int transmutedGrade,
  }) =>
      ops.updateTransmutedGrade(
        _localDataSource,
        _syncQueue,
        classId: classId,
        studentId: studentId,
        termNumber: termNumber,
        transmutedGrade: transmutedGrade,
      );

  @override
  ResultFuture<List<Map<String, dynamic>>> getGradeSummary({
    required String classId,
    required int termNumber,
  }) =>
      ops.getGradeSummary(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        classId: classId,
        termNumber: termNumber,
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
  ResultFuture<List<TermGrade>> getMyGrades({
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
    required int termNumber,
  }) =>
      ops.getMyGradeDetail(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        classId: classId,
        termNumber: termNumber,
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
    bool skipBackgroundRefresh = false,
  }) =>
      ops.getSf9(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        classId: classId,
        studentId: studentId,
        skipBackgroundRefresh: skipBackgroundRefresh,
      );

  @override
  ResultFuture<Sf9Response> getSf10({
    required String classId,
    required String studentId,
    bool skipBackgroundRefresh = false,
  }) {
    // Forward to StudentRecordsRepository when available (new SF10 aggregate)
    if (_studentRecordsRepository != null) {
      return _studentRecordsRepository
          .getSf10(classId: classId, studentId: studentId, skipBackgroundRefresh: skipBackgroundRefresh)
          .then((result) => result.fold(
                (failure) => Left(failure),
                (sf10) => Right(_sf10ToSf9(sf10)),
              ));
    }
    return ops.getSf10(
      _localDataSource,
      _remoteDataSource,
      _dataEventBus,
      classId: classId,
      studentId: studentId,
      skipBackgroundRefresh: skipBackgroundRefresh,
    );
  }

  Sf9Response _sf10ToSf9(Sf10Response sf10) {
    final currentRecord = sf10.scholasticRecords.isNotEmpty
        ? sf10.scholasticRecords.last
        : null;

    final subjects = (currentRecord?.subjects ?? const [])
        .map((s) => Sf9SubjectRow(
              classTitle: s.classTitle,
              subjectGroup: s.subjectGroup,
              termGrades: s.termGrades,
              finalGrade: s.finalGrade,
              descriptor: s.descriptor,
            ))
        .toList();

    return Sf9Response(
      studentId: sf10.studentId,
      studentName: sf10.studentName,
      gradeLevel: sf10.currentGradeLevel,
      schoolYear: sf10.currentSchoolYear,
      section: sf10.currentSection,
      lrn: sf10.lrn,
      age: sf10.age,
      sex: sf10.sex,
      trackStrand: sf10.trackStrand,
      curriculum: sf10.curriculum,
      subjects: subjects,
      generalAverage: () {
        final cr = currentRecord;
        if (cr != null && cr.finalAverage != null) {
          return Sf9TermAverages(
            finalAverage: cr.finalAverage,
            descriptor: cr.descriptor,
          );
        }
        return null;
      }(),
    );
  }

  // ===== Batch Operations =====

  @override
  ResultFuture<Map<String, dynamic>> getGradeDataBatch({
    required String classId,
    required int termNumber,
  }) =>
      ops.getGradeDataBatch(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        classId: classId,
        termNumber: termNumber,
      );

  // ===== Unified Read =====

  @override
  ResultFuture<ClassGrades> getClassGrades({
    required String classId,
    required int termNumber,
    bool skipBackgroundRefresh = false,
  }) =>
      ops.getClassGrades(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        classId: classId,
        termNumber: termNumber,
        skipBackgroundRefresh: skipBackgroundRefresh,
      );
}
