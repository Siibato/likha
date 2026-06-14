import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/entities/submission_file.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';
import 'package:likha/services/storage_service.dart';
import 'operations/assignments.dart' as ops;

class AssignmentRepositoryImpl implements AssignmentRepository {
  final AssignmentRemoteDataSource _remoteDataSource;
  final AssignmentLocalDataSource _localDataSource;
  final SyncQueue _syncQueue;
  final ServerReachabilityService _serverReachabilityService;
  final StorageService _storageService;
  final DataEventBus _dataEventBus;

  AssignmentRepositoryImpl({
    required AssignmentRemoteDataSource remoteDataSource,
    required AssignmentLocalDataSource localDataSource,
    required SyncQueue syncQueue,
    required ServerReachabilityService serverReachabilityService,
    required StorageService storageService,
    required DataEventBus dataEventBus,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _syncQueue = syncQueue,
        _serverReachabilityService = serverReachabilityService,
        _storageService = storageService,
        _dataEventBus = dataEventBus;

  @override
  ResultFuture<Assignment> createAssignment({
    required String classId,
    required String title,
    required String instructions,
    required int totalPoints,
    required bool allowsTextSubmission,
    required bool allowsFileSubmission,
    String? allowedFileTypes,
    int? maxFileSizeMb,
    required String dueAt,
    bool isPublished = true,
    int? gradingPeriodNumber,
    String? component,
    bool? noSubmissionRequired,
  }) =>
      ops.createAssignment(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        classId: classId,
        title: title,
        instructions: instructions,
        totalPoints: totalPoints,
        allowsTextSubmission: allowsTextSubmission,
        allowsFileSubmission: allowsFileSubmission,
        allowedFileTypes: allowedFileTypes,
        maxFileSizeMb: maxFileSizeMb,
        dueAt: dueAt,
        isPublished: isPublished,
        gradingPeriodNumber: gradingPeriodNumber,
        component: component,
        noSubmissionRequired: noSubmissionRequired,
      );

  @override
  ResultFuture<List<Assignment>> getAssignments({
    required String classId,
    bool publishedOnly = false,
    bool skipBackgroundRefresh = false,
  }) =>
      ops.getAssignments(
        _localDataSource,
        _remoteDataSource,
        _storageService,
        _dataEventBus,
        classId: classId,
        publishedOnly: publishedOnly,
        skipBackgroundRefresh: skipBackgroundRefresh,
      );

  @override
  ResultFuture<Assignment> getAssignmentDetail({required String assignmentId}) =>
      ops.getAssignmentDetail(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        assignmentId: assignmentId,
      );

  @override
  ResultFuture<Assignment> updateAssignment({
    required String assignmentId,
    String? title,
    String? instructions,
    int? totalPoints,
    bool? allowsTextSubmission,
    bool? allowsFileSubmission,
    String? allowedFileTypes,
    int? maxFileSizeMb,
    String? dueAt,
  }) =>
      ops.updateAssignment(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        assignmentId: assignmentId,
        title: title,
        instructions: instructions,
        totalPoints: totalPoints,
        allowsTextSubmission: allowsTextSubmission,
        allowsFileSubmission: allowsFileSubmission,
        allowedFileTypes: allowedFileTypes,
        maxFileSizeMb: maxFileSizeMb,
        dueAt: dueAt,
      );

  @override
  ResultVoid deleteAssignment({required String assignmentId}) =>
      ops.deleteAssignment(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        assignmentId: assignmentId,
      );

  @override
  ResultFuture<Assignment> publishAssignment({required String assignmentId}) =>
      ops.publishAssignment(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        assignmentId: assignmentId,
      );

  @override
  ResultFuture<Assignment> unpublishAssignment({required String assignmentId}) =>
      ops.unpublishAssignment(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        assignmentId: assignmentId,
      );

  @override
  ResultVoid reorderAllAssignments({
    required String classId,
    required List<String> assignmentIds,
  }) =>
      ops.reorderAllAssignments(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        classId: classId,
        assignmentIds: assignmentIds,
      );

  @override
  ResultFuture<List<SubmissionListItem>> getSubmissions({required String assignmentId}) =>
      ops.getSubmissions(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        assignmentId: assignmentId,
      );

  @override
  ResultFuture<AssignmentSubmission> getSubmissionDetail({required String submissionId}) =>
      ops.getSubmissionDetail(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        submissionId: submissionId,
      );

  @override
  ResultFuture<AssignmentSubmission> gradeSubmission({
    required String submissionId,
    required int score,
    String? feedback,
  }) =>
      ops.gradeSubmission(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        submissionId: submissionId,
        score: score,
        feedback: feedback,
      );

  @override
  ResultFuture<AssignmentSubmission> returnSubmission({required String submissionId}) =>
      ops.returnSubmission(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        submissionId: submissionId,
      );

  @override
  ResultFuture<StudentAssignmentStatus?> getStudentAssignmentSubmission({
    required String assignmentId,
    required String studentId,
  }) =>
      ops.getStudentAssignmentSubmission(
        _localDataSource,
        _remoteDataSource,
        assignmentId: assignmentId,
        studentId: studentId,
      );

  @override
  ResultFuture<AssignmentSubmission> createSubmission({
    required String assignmentId,
    String? textContent,
  }) =>
      ops.createSubmission(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        _storageService,
        assignmentId: assignmentId,
        textContent: textContent,
      );

  @override
  ResultFuture<SubmissionFile> uploadFile({
    required String submissionId,
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onSendProgress,
  }) =>
      ops.uploadFile(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        submissionId: submissionId,
        filePath: filePath,
        fileName: fileName,
        onSendProgress: onSendProgress,
      );

  @override
  ResultVoid deleteFile({required String fileId}) =>
      ops.deleteFile(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        fileId: fileId,
      );

  @override
  ResultFuture<AssignmentSubmission> submitAssignment({required String submissionId}) =>
      ops.submitAssignment(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        submissionId: submissionId,
      );

  @override
  ResultFuture<List<int>> downloadFile({required String fileId}) =>
      ops.downloadFile(
        _localDataSource,
        _remoteDataSource,
        fileId: fileId,
      );
}