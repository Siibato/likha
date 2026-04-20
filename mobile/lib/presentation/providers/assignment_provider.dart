import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/usecases/create_assignment.dart';
import 'package:likha/domain/assignments/usecases/create_submission.dart';
import 'package:likha/domain/assignments/usecases/delete_assignment.dart';
import 'package:likha/domain/assignments/usecases/delete_file.dart';
import 'package:likha/domain/assignments/usecases/download_file.dart';
import 'package:likha/domain/assignments/usecases/get_assignment_detail.dart';
import 'package:likha/domain/assignments/usecases/get_assignments.dart';
import 'package:likha/domain/assignments/usecases/get_submission_detail.dart';
import 'package:likha/domain/assignments/usecases/get_submissions.dart';
import 'package:likha/domain/assignments/usecases/grade_submission.dart';
import 'package:likha/domain/assignments/usecases/publish_assignment.dart';
import 'package:likha/domain/assignments/usecases/unpublish_assignment.dart';
import 'package:likha/domain/assignments/usecases/return_submission.dart';
import 'package:likha/domain/assignments/usecases/submit_assignment.dart';
import 'package:likha/domain/assignments/usecases/update_assignment.dart';
import 'package:likha/domain/assignments/usecases/upload_file.dart';
import 'package:likha/domain/assignments/usecases/reorder_assignment.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';
import 'package:likha/injection_container.dart';

class AssignmentState {
  final List<Assignment> assignments;
  final Assignment? currentAssignment;
  final List<SubmissionListItem> submissions;
  final AssignmentSubmission? currentSubmission;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final double uploadProgress; // 0.0 to 1.0
  final String? currentUploadFileName;

  AssignmentState({
    this.assignments = const [],
    this.currentAssignment,
    this.submissions = const [],
    this.currentSubmission,
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.uploadProgress = 0.0,
    this.currentUploadFileName,
  });

  AssignmentState copyWith({
    List<Assignment>? assignments,
    Assignment? currentAssignment,
    List<SubmissionListItem>? submissions,
    AssignmentSubmission? currentSubmission,
    bool? isLoading,
    String? error,
    String? successMessage,
    double? uploadProgress,
    String? currentUploadFileName,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearAssignment = false,
    bool clearSubmission = false,
    bool clearUploadProgress = false,
  }) {
    return AssignmentState(
      assignments: assignments ?? this.assignments,
      currentAssignment: clearAssignment
          ? null
          : (currentAssignment ?? this.currentAssignment),
      submissions: submissions ?? this.submissions,
      currentSubmission: clearSubmission
          ? null
          : (currentSubmission ?? this.currentSubmission),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      uploadProgress: clearUploadProgress ? 0.0 : (uploadProgress ?? this.uploadProgress),
      currentUploadFileName: clearUploadProgress ? null : (currentUploadFileName ?? this.currentUploadFileName),
    );
  }
}

class AssignmentNotifier extends StateNotifier<AssignmentState> {
  final CreateAssignment _createAssignment;
  final GetAssignments _getAssignments;
  final GetAssignmentDetail _getAssignmentDetail;
  final UpdateAssignment _updateAssignment;
  final DeleteAssignment _deleteAssignment;
  final PublishAssignment _publishAssignment;
  final UnpublishAssignment _unpublishAssignment;
  final GetAssignmentSubmissions _getSubmissions;
  final GetAssignmentSubmissionDetail _getSubmissionDetail;
  final GradeSubmission _gradeSubmission;
  final ReturnSubmission _returnSubmission;
  final CreateSubmission _createSubmission;
  final UploadFile _uploadFile;
  final DeleteFile _deleteFile;
  final SubmitAssignment _submitAssignment;
  final DownloadFile _downloadFile;
  final ReorderAllAssignments _reorderAllAssignments;

  String? _currentClassId;
  bool _currentPublishedOnly = false;
  late StreamSubscription<String?> _refreshSub;
  late StreamSubscription<String> _submissionDetailRefreshSub;

  AssignmentNotifier(
    this._createAssignment,
    this._getAssignments,
    this._getAssignmentDetail,
    this._updateAssignment,
    this._deleteAssignment,
    this._publishAssignment,
    this._unpublishAssignment,
    this._getSubmissions,
    this._getSubmissionDetail,
    this._gradeSubmission,
    this._returnSubmission,
    this._createSubmission,
    this._uploadFile,
    this._deleteFile,
    this._submitAssignment,
    this._downloadFile,
    this._reorderAllAssignments,
  ) : super(AssignmentState()) {
    _refreshSub = sl<DataEventBus>().onAssignmentsChanged.listen((classId) {
      if (_currentClassId != null && _currentClassId == classId) {
        loadAssignments(_currentClassId!, publishedOnly: _currentPublishedOnly, skipBackgroundRefresh: true);
      }
    });

    _submissionDetailRefreshSub = sl<DataEventBus>().onSubmissionDetailChanged.listen((submissionId) {
      if (state.currentSubmission?.id == submissionId) {
        loadSubmissionDetail(submissionId);
      }
    });
  }

  Future<void> loadAssignments(String classId, {bool publishedOnly = false, bool skipBackgroundRefresh = false}) async {
    _currentClassId = classId;
    _currentPublishedOnly = publishedOnly;
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getAssignments(classId, publishedOnly: publishedOnly, skipBackgroundRefresh: skipBackgroundRefresh);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (assignments) =>
          state = state.copyWith(isLoading: false, assignments: assignments),
    );
  }

  String _toGradeComponent(String c) {
    switch (c) {
      case 'written_work': return 'ww';
      case 'performance_task': return 'pt';
      case 'quarterly_assessment': return 'qa';
      default: return c;
    }
  }

  Future<void> createAssignment(CreateAssignmentParams params) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _createAssignment(params);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (assignment) {
        state = state.copyWith(
          isLoading: false,
          assignments: [assignment, ...state.assignments],
          currentAssignment: assignment,
          successMessage: 'Assignment created',
        );
        // Auto-create linked grade item when component + gradingPeriodNumber are set
        if (assignment.component != null && assignment.gradingPeriodNumber != null) {
          sl<GradingRepository>().createGradeItem(
            classId: params.classId,
            data: {
              'title': assignment.title,
              'component': _toGradeComponent(assignment.component!),
              'grading_period_number': assignment.gradingPeriodNumber!,
              'total_points': assignment.totalPoints.toDouble(),
              'is_departmental_exam': false,
              'source_type': 'assignment',
              'source_id': assignment.id,
              'order_index': 0,
            },
          );
        }
      },
    );
  }

  Future<void> loadAssignmentDetail(String assignmentId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getAssignmentDetail(assignmentId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (assignment) => state = state.copyWith(
        isLoading: false,
        currentAssignment: assignment,
      ),
    );
  }

  Future<void> updateAssignment(UpdateAssignmentParams params) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _updateAssignment(params);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (assignment) {
        state = state.copyWith(
          isLoading: false,
          currentAssignment: assignment,
          successMessage: 'Assignment updated',
        );
        // Sync title/total_points to linked grade item if one exists
        sl<GradingRepository>().findGradeItemBySourceId(params.assignmentId).then((res) {
          res.fold((_) {}, (item) {
            if (item != null) {
              final updates = <String, dynamic>{};
              if (params.title != null) updates['title'] = params.title;
              if (params.totalPoints != null) updates['total_points'] = params.totalPoints!.toDouble();
              if (updates.isNotEmpty) {
                sl<GradingRepository>().updateGradeItem(id: item.id, data: updates);
              }
            }
          });
        });
      },
    );
  }

  Future<void> publishAssignment(String assignmentId) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _publishAssignment(assignmentId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (assignment) => state = state.copyWith(
        isLoading: false,
        currentAssignment: assignment,
        successMessage: 'Assignment published',
      ),
    );
  }

  Future<void> unpublishAssignment(String assignmentId) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _unpublishAssignment(assignmentId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (assignment) => state = state.copyWith(
        isLoading: false,
        currentAssignment: assignment,
        successMessage: 'Assignment moved to draft',
      ),
    );
  }

  Future<void> deleteAssignment(String assignmentId) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _deleteAssignment(assignmentId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (_) {
        state = state.copyWith(
          isLoading: false,
          assignments:
              state.assignments.where((a) => a.id != assignmentId).toList(),
          successMessage: 'Assignment deleted',
          clearAssignment: true,
        );
        // Delete linked grade item if one exists
        sl<GradingRepository>().findGradeItemBySourceId(assignmentId).then((res) {
          res.fold((_) {}, (item) {
            if (item != null) {
              sl<GradingRepository>().deleteGradeItem(id: item.id);
            }
          });
        });
      },
    );
  }

  Future<void> reorderAllAssignments({
    required String classId,
    required List<String> assignmentIds,
    required List<Assignment> orderedAssignments,
  }) async {
    // Optimistic update
    state = state.copyWith(assignments: orderedAssignments);
    final result = await _reorderAllAssignments(
      classId: classId,
      assignmentIds: assignmentIds,
    );
    result.fold(
      (failure) => state = state.copyWith(error: AppErrorMapper.fromFailure(failure)),
      (_) {},
    );
  }

  /// Downloads all submission files across all loaded submissions that aren't already cached.
  /// Returns (downloaded, totalUncached):
  ///   - downloaded: number of files successfully downloaded
  ///   - totalUncached: total number of uncached files found (attempted downloads)
  /// Sets state.error if server is unreachable.
  Future<(int, int)> downloadAllSubmissionFiles() async {
    if (!sl<ServerReachabilityService>().isServerReachable) {
      state = state.copyWith(error: 'No server connection. Please connect and try again.');
      return (0, 0);
    }

    int downloaded = 0;
    int totalUncached = 0;
    for (final submission in state.submissions) {
      final detailResult = await _getSubmissionDetail(submission.id);
      await detailResult.fold(
        (_) async {}, // silently skip — don't abort entire batch for one failure
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

  /// Silently re-fetches the assignment from local DB to pick up fresh submission
  /// counts after cacheSubmissions() has written new rows to assignment_submissions.
  Future<void> _refreshAssignmentCounts(String assignmentId) async {
    final result = await _getAssignmentDetail(assignmentId);
    result.fold(
      (_) {}, // best-effort — silently ignore errors
      (fresh) {
        state = state.copyWith(
          assignments: state.assignments
              .map((a) => a.id == assignmentId ? fresh : a)
              .toList(),
          currentAssignment: state.currentAssignment?.id == assignmentId
              ? fresh
              : state.currentAssignment,
        );
      },
    );
  }

  // Teacher: Submissions
  Future<void> loadSubmissions(String assignmentId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getSubmissions(assignmentId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (submissions) {
        state = state.copyWith(isLoading: false, submissions: submissions);
        // Background: refresh assignment counts now that submissions are cached
        unawaited(_refreshAssignmentCounts(assignmentId));
      },
    );
  }

  Future<void> loadSubmissionDetail(String submissionId) async {
    print('DEBUG: Loading submission detail for ID: $submissionId');
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getSubmissionDetail(submissionId);
    result.fold(
      (failure) {
        // For offline-first behavior, don't show network errors if we might have cached data
        // Check if this is likely an offline submission scenario
        final isNetworkFailure = failure.toString().toLowerCase().contains('connection') || 
                                failure.toString().toLowerCase().contains('network') ||
                                failure.toString().toLowerCase().contains('server unreachable');
        
        if (isNetworkFailure) {
          // Try to load from cache as fallback for offline scenarios
          // For now, set a user-friendly error message instead of silent failure
          state = state.copyWith(
            isLoading: false, 
            error: 'Unable to load submission details. Check your connection and try again.'
          );
          return;
        }
        
        state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure));
      },
      (submission) {
        print('DEBUG: Successfully loaded submission: ${submission.studentName}');
        state = state.copyWith(isLoading: false, currentSubmission: submission);
      },
    );
  }

  Future<void> gradeSubmission(GradeSubmissionParams params) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _gradeSubmission(params);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (submission) => state = state.copyWith(
        isLoading: false,
        currentSubmission: submission,
        successMessage: 'Submission graded',
      ),
    );
  }

  Future<void> returnSubmission(String submissionId) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _returnSubmission(submissionId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (submission) => state = state.copyWith(
        isLoading: false,
        currentSubmission: submission,
        successMessage: 'Submission returned for revision',
      ),
    );
  }

  // Student: Submission flow
  Future<void> createSubmission(CreateSubmissionParams params) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _createSubmission(params);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (submission) => state = state.copyWith(
        isLoading: false,
        currentSubmission: submission,
        successMessage: 'Submission created',
      ),
    );
  }

  Future<void> uploadFile(UploadFileParams params) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
      clearUploadProgress: true,
      currentUploadFileName: params.fileName,
    );

    final result = await _uploadFile(
      UploadFileParams(
        submissionId: params.submissionId,
        filePath: params.filePath,
        fileName: params.fileName,
        onSendProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(uploadProgress: sent / total);
          }
        },
      ),
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
        clearUploadProgress: true,
      ),
      (_) => state = state.copyWith(
        isLoading: false,
        successMessage: 'File uploaded',
        clearUploadProgress: true,
      ),
    );
  }

  Future<void> deleteSubmissionFile(String fileId) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _deleteFile(fileId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (_) => state = state.copyWith(
        isLoading: false,
        successMessage: 'File deleted',
      ),
    );
  }

  Future<void> submitAssignment(String submissionId) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _submitAssignment(submissionId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (submission) => state = state.copyWith(
        isLoading: false,
        currentSubmission: submission,
        successMessage: 'Assignment submitted',
      ),
    );
  }

  Future<List<int>?> downloadFile(String fileId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _downloadFile(fileId);
    state = state.copyWith(isLoading: false);

    List<int>? fileBytes;
    bool success = false;
    result.fold(
      (failure) => state = state.copyWith(error: AppErrorMapper.fromFailure(failure)),
      (bytes) {
        fileBytes = bytes;
        success = true;
      },
    );

    if (success && state.currentSubmission != null) {
      // Await reload so localPath is updated before caller reads state
      await loadSubmissionDetail(state.currentSubmission!.id);
    }
    return fileBytes;
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  void clearCurrentSubmission() {
    state = state.copyWith(clearSubmission: true);
  }

  @override
  void dispose() {
    _refreshSub.cancel();
    _submissionDetailRefreshSub.cancel();
    super.dispose();
  }
}

final assignmentProvider =
    StateNotifierProvider<AssignmentNotifier, AssignmentState>((ref) {
  return AssignmentNotifier(
    sl<CreateAssignment>(),
    sl<GetAssignments>(),
    sl<GetAssignmentDetail>(),
    sl<UpdateAssignment>(),
    sl<DeleteAssignment>(),
    sl<PublishAssignment>(),
    sl<UnpublishAssignment>(),
    sl<GetAssignmentSubmissions>(),
    sl<GetAssignmentSubmissionDetail>(),
    sl<GradeSubmission>(),
    sl<ReturnSubmission>(),
    sl<CreateSubmission>(),
    sl<UploadFile>(),
    sl<DeleteFile>(),
    sl<SubmitAssignment>(),
    sl<DownloadFile>(),
    sl<ReorderAllAssignments>(),
  );
});
