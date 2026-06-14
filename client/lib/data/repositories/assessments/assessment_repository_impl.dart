import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/network/connectivity_service.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';
import 'package:likha/data/validation/services/validation_service.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';
import 'package:likha/services/storage_service.dart';
import 'operations/assessments.dart' as ops;

class AssessmentRepositoryImpl implements AssessmentRepository {
  final AssessmentRemoteDataSource _remoteDataSource;
  final AssessmentLocalDataSource _localDataSource;
  // ignore: unused_field
  final ValidationService _validationService;
  // ignore: unused_field
  final ConnectivityService _connectivityService;
  final SyncQueue _syncQueue;
  final ServerReachabilityService _serverReachabilityService;
  final StorageService _storageService;
  final DataEventBus _dataEventBus;

  AssessmentRepositoryImpl({
    required AssessmentRemoteDataSource remoteDataSource,
    required AssessmentLocalDataSource localDataSource,
    required ValidationService validationService,
    required ConnectivityService connectivityService,
    required SyncQueue syncQueue,
    required ServerReachabilityService serverReachabilityService,
    required StorageService storageService,
    required DataEventBus dataEventBus,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _validationService = validationService,
        _connectivityService = connectivityService,
        _syncQueue = syncQueue,
        _serverReachabilityService = serverReachabilityService,
        _storageService = storageService,
        _dataEventBus = dataEventBus;

  @override
  ResultFuture<Assessment> createAssessment({
    required String classId,
    required String title,
    String? description,
    required int timeLimitMinutes,
    required String openAt,
    required String closeAt,
    bool? showResultsImmediately,
    bool isPublished = true,
    List<Map<String, dynamic>>? questions,
    int? gradingPeriodNumber,
    String? component,
    String? tosId,
  }) =>
      ops.createAssessment(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        classId: classId,
        title: title,
        description: description,
        timeLimitMinutes: timeLimitMinutes,
        openAt: openAt,
        closeAt: closeAt,
        showResultsImmediately: showResultsImmediately,
        isPublished: isPublished,
        questions: questions,
        gradingPeriodNumber: gradingPeriodNumber,
        component: component,
        tosId: tosId,
      );

  @override
  ResultFuture<List<Assessment>> getAssessments({
    required String classId,
    bool publishedOnly = false,
    bool skipBackgroundRefresh = false,
  }) =>
      ops.getAssessments(
        _localDataSource,
        _remoteDataSource,
        _storageService,
        _dataEventBus,
        classId: classId,
        publishedOnly: publishedOnly,
        skipBackgroundRefresh: skipBackgroundRefresh,
      );

  @override
  ResultFuture<(Assessment, List<Question>)> getAssessmentDetail({
    required String assessmentId,
  }) =>
      ops.getAssessmentDetail(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        assessmentId: assessmentId,
      );

  @override
  ResultFuture<Assessment> updateAssessment({
    required String assessmentId,
    String? title,
    String? description,
    int? timeLimitMinutes,
    String? openAt,
    String? closeAt,
    bool? showResultsImmediately,
    int? gradingPeriodNumber,
    String? component,
  }) =>
      ops.updateAssessment(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        assessmentId: assessmentId,
        title: title,
        description: description,
        timeLimitMinutes: timeLimitMinutes,
        openAt: openAt,
        closeAt: closeAt,
        showResultsImmediately: showResultsImmediately,
        gradingPeriodNumber: gradingPeriodNumber,
        component: component,
      );

  @override
  ResultVoid deleteAssessment({required String assessmentId}) =>
      ops.deleteAssessment(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        assessmentId: assessmentId,
      );

  @override
  ResultFuture<Assessment> publishAssessment({
    required String assessmentId,
  }) =>
      ops.publishAssessment(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        assessmentId: assessmentId,
      );

  @override
  ResultFuture<Assessment> unpublishAssessment({
    required String assessmentId,
  }) =>
      ops.unpublishAssessment(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        assessmentId: assessmentId,
      );

  @override
  ResultFuture<Assessment> releaseResults({
    required String assessmentId,
  }) =>
      ops.releaseResults(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        assessmentId: assessmentId,
      );

  @override
  ResultVoid reorderAllAssessments({
    required String classId,
    required List<String> assessmentIds,
  }) =>
      ops.reorderAllAssessments(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        classId: classId,
        assessmentIds: assessmentIds,
      );

  @override
  ResultFuture<List<Question>> addQuestions({
    required String assessmentId,
    required List<Map<String, dynamic>> questions,
  }) =>
      ops.addQuestions(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        assessmentId: assessmentId,
        questions: questions,
      );

  @override
  ResultFuture<Question> updateQuestion({
    required String questionId,
    required Map<String, dynamic> data,
  }) =>
      ops.updateQuestion(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        questionId: questionId,
        data: data,
      );

  @override
  ResultVoid deleteQuestion({required String questionId}) =>
      ops.deleteQuestion(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        questionId: questionId,
      );

  @override
  ResultVoid reorderQuestions({
    required String assessmentId,
    required List<String> questionIds,
  }) =>
      ops.reorderQuestions(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        assessmentId: assessmentId,
        questionIds: questionIds,
      );

  @override
  ResultFuture<List<SubmissionSummary>> getSubmissions({
    required String assessmentId,
  }) =>
      ops.getSubmissions(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        assessmentId: assessmentId,
      );

  @override
  ResultFuture<SubmissionDetail> getSubmissionDetail({
    required String submissionId,
  }) =>
      ops.getSubmissionDetail(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        submissionId: submissionId,
      );

  @override
  ResultFuture<SubmissionAnswer> overrideAnswer({
    required String answerId,
    required bool isCorrect,
    double? points,
  }) =>
      ops.overrideAnswer(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        answerId: answerId,
        isCorrect: isCorrect,
        points: points,
      );

  @override
  ResultFuture<SubmissionAnswer> gradeEssayAnswer({
    required String answerId,
    required double points,
  }) =>
      ops.gradeEssayAnswer(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        answerId: answerId,
        points: points,
      );

  @override
  ResultFuture<AssessmentStatistics> getStatistics({
    required String assessmentId,
  }) =>
      ops.getStatistics(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        assessmentId: assessmentId,
      );

  @override
  ResultFuture<StartSubmissionResult> startAssessment({
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
  }) =>
      ops.startAssessment(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        assessmentId: assessmentId,
        studentId: studentId,
        studentName: studentName,
        studentUsername: studentUsername,
      );

  @override
  ResultFuture<SubmissionSummary?> getStudentSubmission({
    required String assessmentId,
    required String studentId,
  }) =>
      ops.getStudentSubmission(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        assessmentId: assessmentId,
        studentId: studentId,
      );

  @override
  ResultVoid saveAnswers({
    required String submissionId,
    required List<Map<String, dynamic>> answers,
  }) =>
      ops.saveAnswers(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        submissionId: submissionId,
        answers: answers,
      );

  @override
  ResultFuture<SubmissionSummary> submitAssessment({
    required String submissionId,
  }) =>
      ops.submitAssessment(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        submissionId: submissionId,
      );

  @override
  ResultFuture<StudentResult> getStudentResults({
    required String submissionId,
  }) =>
      ops.getStudentResults(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        submissionId: submissionId,
      );
}