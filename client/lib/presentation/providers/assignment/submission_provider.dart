import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/logging/provider_logger.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/entities/submission_file.dart';
import 'package:likha/domain/assignments/usecases/create_submission.dart';
import 'package:likha/domain/assignments/usecases/delete_file.dart';
import 'package:likha/domain/assignments/usecases/download_file.dart';
import 'package:likha/domain/assignments/usecases/get_submission_detail.dart';
import 'package:likha/domain/assignments/usecases/get_submissions.dart';
import 'package:likha/domain/assignments/usecases/grade_submission.dart';
import 'package:likha/domain/assignments/usecases/return_submission.dart';
import 'package:likha/domain/assignments/usecases/submit_assignment.dart';
import 'package:likha/injection_container.dart';

class SubmissionState {
  final List<SubmissionListItem> submissions;
  final AssignmentSubmission? currentSubmission;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  SubmissionState({
    this.submissions = const [],
    this.currentSubmission,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  SubmissionState copyWith({
    List<SubmissionListItem>? submissions,
    AssignmentSubmission? currentSubmission,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearSubmission = false,
  }) {
    return SubmissionState(
      submissions: submissions ?? this.submissions,
      currentSubmission: clearSubmission
          ? null
          : (currentSubmission ?? this.currentSubmission),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class SubmissionNotifier extends StateNotifier<SubmissionState> {
  final Ref ref;
  final GetAssignmentSubmissions _getSubmissions;
  final GetAssignmentSubmissionDetail _getSubmissionDetail;
  final GradeSubmission _gradeSubmission;
  final ReturnSubmission _returnSubmission;
  final CreateSubmission _createSubmission;
  final DeleteFile _deleteFile;
  final SubmitAssignment _submitAssignment;
  final DownloadFile _downloadFile;

  String? _currentSubmissionId;

  SubmissionNotifier(
    this.ref,
    this._getSubmissions,
    this._getSubmissionDetail,
    this._gradeSubmission,
    this._returnSubmission,
    this._createSubmission,
    this._deleteFile,
    this._submitAssignment,
    this._downloadFile,
  ) : super(SubmissionState());

  AssignmentSubmission _copySubmission(
    AssignmentSubmission source, {
    String? status,
    String? textContent,
    DateTime? submittedAt,
    int? score,
    String? feedback,
    DateTime? gradedAt,
    String? gradedBy,
    List<SubmissionFile>? files,
    DateTime? updatedAt,
    DateTime? cachedAt,
    SyncStatus? syncStatus,
  }) {
    return AssignmentSubmission(
      id: source.id,
      assignmentId: source.assignmentId,
      studentId: source.studentId,
      studentName: source.studentName,
      status: status ?? source.status,
      textContent: textContent ?? source.textContent,
      submittedAt: submittedAt ?? source.submittedAt,
      score: score ?? source.score,
      feedback: feedback ?? source.feedback,
      gradedAt: gradedAt ?? source.gradedAt,
      gradedBy: gradedBy ?? source.gradedBy,
      files: files ?? source.files,
      createdAt: source.createdAt,
      updatedAt: updatedAt ?? source.updatedAt,
      cachedAt: cachedAt ?? source.cachedAt,
      syncStatus: syncStatus ?? source.syncStatus,
    );
  }

  Future<void> loadSubmissions(String assignmentId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getSubmissions(assignmentId);
    result.fold(
      (failure) => state = state.copyWith(
          isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (submissions) {
        state = state.copyWith(isLoading: false, submissions: submissions);
      },
    );
  }

  Future<void> loadSubmissionDetail(String submissionId) async {
    ProviderLogger.instance
        .log('Loading submission detail for ID: $submissionId');
    if (_currentSubmissionId != submissionId) {
      _currentSubmissionId = submissionId;
      state = state.copyWith(
          isLoading: true, clearError: true, clearSubmission: true);
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    final result = await _getSubmissionDetail(submissionId);
    result.fold(
      (failure) {
        final isNetworkFailure = failure.toString().toLowerCase().contains('connection') ||
            failure.toString().toLowerCase().contains('network') ||
            failure.toString().toLowerCase().contains('server unreachable');

        if (isNetworkFailure) {
          state = state.copyWith(
            isLoading: false,
            error:
                'Unable to load submission details. Check your connection and try again.',
          );
          return;
        }

        state =
            state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure));
      },
      (submission) {
        ProviderLogger.instance
            .log('Successfully loaded submission: ${submission.studentName}');
        state = state.copyWith(isLoading: false, currentSubmission: submission);
      },
    );
  }

  Future<void> gradeSubmission(GradeSubmissionParams params) async {
    state = state.copyWith(clearError: true, clearSuccess: true);
    final result = await _gradeSubmission(params);
    result.fold(
      (failure) =>
          state = state.copyWith(error: AppErrorMapper.fromFailure(failure)),
      (mutationResult) => state = state.copyWith(
        currentSubmission: mutationResult.entity,
        successMessage: 'Submission graded',
      ),
    );
  }

  Future<void> returnSubmission(String submissionId) async {
    state = state.copyWith(clearError: true, clearSuccess: true);
    final result = await _returnSubmission(submissionId);
    result.fold(
      (failure) =>
          state = state.copyWith(error: AppErrorMapper.fromFailure(failure)),
      (mutationResult) => state = state.copyWith(
        currentSubmission: mutationResult.entity,
        successMessage: 'Submission returned for revision',
      ),
    );
  }

  Future<void> createSubmission(CreateSubmissionParams params) async {
    state = state.copyWith(clearError: true, clearSuccess: true);
    final result = await _createSubmission(params);
    result.fold(
      (failure) =>
          state = state.copyWith(error: AppErrorMapper.fromFailure(failure)),
      (mutationResult) => state = state.copyWith(
        currentSubmission: mutationResult.entity,
        successMessage: 'Submission created',
      ),
    );
  }

  Future<void> deleteSubmissionFile(String fileId) async {
    state = state.copyWith(clearError: true, clearSuccess: true);
    final result = await _deleteFile(fileId);
    result.fold(
      (failure) =>
          state = state.copyWith(error: AppErrorMapper.fromFailure(failure)),
      (mutationResult) {
        final submission = state.currentSubmission;
        if (submission != null) {
          state = state.copyWith(
            currentSubmission: _copySubmission(
              submission,
              files: submission.files.where((f) => f.id != fileId).toList(),
              updatedAt: DateTime.now(),
            ),
            successMessage: 'File deleted',
          );
        } else {
          state = state.copyWith(successMessage: 'File deleted');
        }
      },
    );
  }

  Future<void> submitAssignment(String submissionId) async {
    state = state.copyWith(clearError: true, clearSuccess: true);
    final result = await _submitAssignment(submissionId);
    result.fold(
      (failure) =>
          state = state.copyWith(error: AppErrorMapper.fromFailure(failure)),
      (mutationResult) => state = state.copyWith(
        currentSubmission: mutationResult.entity,
        successMessage: 'Assignment submitted',
      ),
    );
  }

  Future<(int, int)> downloadAllSubmissionFiles() async {
    if (!sl<ServerReachabilityService>().isServerReachable) {
      state = state.copyWith(
          error: 'No server connection. Please connect and try again.');
      return (0, 0);
    }

    int downloaded = 0;
    int totalUncached = 0;
    for (final submission in state.submissions) {
      final detailResult = await _getSubmissionDetail(submission.id);
      await detailResult.fold(
        (_) async {},
        (detail) async {
          for (final file in detail.files) {
            if (!file.isCached) {
              totalUncached++;
              final result = await _downloadFile(file.id);
              result.fold((_) {}, (_) => downloaded++);
            }
          }
        },
      );
    }
    return (downloaded, totalUncached);
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  void clearCurrentSubmission() {
    state = state.copyWith(clearSubmission: true);
  }

  void handleFileUploaded(String submissionId, SubmissionFile file) {
    final submission = state.currentSubmission;
    if (submission == null || submission.id != submissionId) {
      state = state.copyWith(successMessage: 'File uploaded');
      return;
    }

    state = state.copyWith(
      currentSubmission: _copySubmission(
        submission,
        files: [...submission.files, file],
        updatedAt: DateTime.now(),
      ),
      successMessage: 'File uploaded',
    );
  }

  String? get currentError => state.error;

  SubmissionState get currentState => state;
}

final submissionProvider =
    StateNotifierProvider<SubmissionNotifier, SubmissionState>((ref) {
  return SubmissionNotifier(
    ref,
    sl<GetAssignmentSubmissions>(),
    sl<GetAssignmentSubmissionDetail>(),
    sl<GradeSubmission>(),
    sl<ReturnSubmission>(),
    sl<CreateSubmission>(),
    sl<DeleteFile>(),
    sl<SubmitAssignment>(),
    sl<DownloadFile>(),
  );
});
