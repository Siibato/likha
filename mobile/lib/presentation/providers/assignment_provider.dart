import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:likha/domain/assignments/usecases/return_submission.dart';
import 'package:likha/domain/assignments/usecases/submit_assignment.dart';
import 'package:likha/domain/assignments/usecases/update_assignment.dart';
import 'package:likha/domain/assignments/usecases/upload_file.dart';
import 'package:likha/injection_container.dart';

class AssignmentState {
  final List<Assignment> assignments;
  final Assignment? currentAssignment;
  final List<SubmissionListItem> submissions;
  final AssignmentSubmission? currentSubmission;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  AssignmentState({
    this.assignments = const [],
    this.currentAssignment,
    this.submissions = const [],
    this.currentSubmission,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  AssignmentState copyWith({
    List<Assignment>? assignments,
    Assignment? currentAssignment,
    List<SubmissionListItem>? submissions,
    AssignmentSubmission? currentSubmission,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearAssignment = false,
    bool clearSubmission = false,
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
  final GetAssignmentSubmissions _getSubmissions;
  final GetAssignmentSubmissionDetail _getSubmissionDetail;
  final GradeSubmission _gradeSubmission;
  final ReturnSubmission _returnSubmission;
  final CreateSubmission _createSubmission;
  final UploadFile _uploadFile;
  final DeleteFile _deleteFile;
  final SubmitAssignment _submitAssignment;
  final DownloadFile _downloadFile;

  AssignmentNotifier(
    this._createAssignment,
    this._getAssignments,
    this._getAssignmentDetail,
    this._updateAssignment,
    this._deleteAssignment,
    this._publishAssignment,
    this._getSubmissions,
    this._getSubmissionDetail,
    this._gradeSubmission,
    this._returnSubmission,
    this._createSubmission,
    this._uploadFile,
    this._deleteFile,
    this._submitAssignment,
    this._downloadFile,
  ) : super(AssignmentState());

  Future<void> loadAssignments(String classId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getAssignments(classId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (assignments) =>
          state = state.copyWith(isLoading: false, assignments: assignments),
    );
  }

  Future<void> createAssignment(CreateAssignmentParams params) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _createAssignment(params);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (assignment) {
        state = state.copyWith(
          isLoading: false,
          assignments: [assignment, ...state.assignments],
          currentAssignment: assignment,
          successMessage: 'Assignment created',
        );
      },
    );
  }

  Future<void> loadAssignmentDetail(String assignmentId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getAssignmentDetail(assignmentId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
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
          state = state.copyWith(isLoading: false, error: failure.message),
      (assignment) => state = state.copyWith(
        isLoading: false,
        currentAssignment: assignment,
        successMessage: 'Assignment updated',
      ),
    );
  }

  Future<void> publishAssignment(String assignmentId) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _publishAssignment(assignmentId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (assignment) => state = state.copyWith(
        isLoading: false,
        currentAssignment: assignment,
        successMessage: 'Assignment published',
      ),
    );
  }

  Future<void> deleteAssignment(String assignmentId) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _deleteAssignment(assignmentId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (_) {
        state = state.copyWith(
          isLoading: false,
          assignments:
              state.assignments.where((a) => a.id != assignmentId).toList(),
          successMessage: 'Assignment deleted',
          clearAssignment: true,
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
          state = state.copyWith(isLoading: false, error: failure.message),
      (submissions) =>
          state = state.copyWith(isLoading: false, submissions: submissions),
    );
  }

  Future<void> loadSubmissionDetail(String submissionId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getSubmissionDetail(submissionId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (submission) => state =
          state.copyWith(isLoading: false, currentSubmission: submission),
    );
  }

  Future<void> gradeSubmission(GradeSubmissionParams params) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _gradeSubmission(params);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
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
          state = state.copyWith(isLoading: false, error: failure.message),
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
          state = state.copyWith(isLoading: false, error: failure.message),
      (submission) => state = state.copyWith(
        isLoading: false,
        currentSubmission: submission,
        successMessage: 'Submission created',
      ),
    );
  }

  Future<void> uploadFile(UploadFileParams params) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _uploadFile(params);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (_) => state = state.copyWith(
        isLoading: false,
        successMessage: 'File uploaded',
      ),
    );
  }

  Future<void> deleteSubmissionFile(String fileId) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _deleteFile(fileId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
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
          state = state.copyWith(isLoading: false, error: failure.message),
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
    List<int>? fileBytes;
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (bytes) {
        fileBytes = bytes;
        state = state.copyWith(isLoading: false);
      },
    );
    return fileBytes;
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
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
    sl<GetAssignmentSubmissions>(),
    sl<GetAssignmentSubmissionDetail>(),
    sl<GradeSubmission>(),
    sl<ReturnSubmission>(),
    sl<CreateSubmission>(),
    sl<UploadFile>(),
    sl<DeleteFile>(),
    sl<SubmitAssignment>(),
    sl<DownloadFile>(),
  );
});
