import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/logging/provider_logger.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assessments/usecases/get_assessments.dart';
import 'package:likha/domain/assessments/usecases/get_assessment_detail.dart';
import 'package:likha/domain/assessments/usecases/get_student_submission.dart';
import 'package:likha/domain/assessments/usecases/get_student_results.dart';
import 'package:likha/domain/assessments/usecases/save_answers.dart';
import 'package:likha/domain/assessments/usecases/start_assessment.dart';
import 'package:likha/domain/assessments/usecases/submit_assessment.dart';
import 'package:likha/injection_container.dart';

const _unset = Object();

class StudentAssessmentState {
  final List<Assessment> assessments;
  final Assessment? currentAssessment;
  final StartSubmissionResult? startResult;
  final SubmissionSummary? currentStudentSubmission;
  final StudentResult? studentResult;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  StudentAssessmentState({
    this.assessments = const [],
    this.currentAssessment,
    this.startResult,
    this.currentStudentSubmission,
    this.studentResult,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  StudentAssessmentState copyWith({
    List<Assessment>? assessments,
    Object? currentAssessment = _unset,
    Object? startResult = _unset,
    Object? currentStudentSubmission = _unset,
    Object? studentResult = _unset,
    bool? isLoading,
    Object? error = _unset,
    Object? successMessage = _unset,
  }) {
    return StudentAssessmentState(
      assessments: assessments ?? this.assessments,
      currentAssessment: identical(currentAssessment, _unset) ? this.currentAssessment : currentAssessment as Assessment?,
      startResult: identical(startResult, _unset) ? this.startResult : startResult as StartSubmissionResult?,
      currentStudentSubmission: identical(currentStudentSubmission, _unset) ? this.currentStudentSubmission : currentStudentSubmission as SubmissionSummary?,
      studentResult: identical(studentResult, _unset) ? this.studentResult : studentResult as StudentResult?,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      successMessage: identical(successMessage, _unset) ? this.successMessage : successMessage as String?,
    );
  }
}

class StudentAssessmentNotifier extends StateNotifier<StudentAssessmentState> {
  final GetAssessments _getAssessments;
  final GetAssessmentDetail _getAssessmentDetail;
  final StartAssessment _startAssessment;
  final SaveAnswers _saveAnswers;
  final SubmitAssessment _submitAssessment;
  final GetStudentResults _getStudentResults;
  final GetStudentSubmission _getStudentSubmission;

  StudentAssessmentNotifier(
    this._getAssessments,
    this._getAssessmentDetail,
    this._startAssessment,
    this._saveAnswers,
    this._submitAssessment,
    this._getStudentResults,
    this._getStudentSubmission,
  ) : super(StudentAssessmentState());

  Future<void> loadAssessments(String classId, {bool publishedOnly = false, bool skipBackgroundRefresh = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getAssessments(classId, publishedOnly: publishedOnly, skipBackgroundRefresh: skipBackgroundRefresh);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (assessments) => state = state.copyWith(isLoading: false, assessments: assessments),
    );
  }

  Future<void> loadAssessmentDetail(String assessmentId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getAssessmentDetail(assessmentId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (data) {
        final (assessment, _) = data;
        state = state.copyWith(isLoading: false, currentAssessment: assessment);
      },
    );
  }

  Future<void> startAssessment(
    String assessmentId,
    String studentId,
    String studentName,
    String studentUsername,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _startAssessment(StartAssessmentParams(
      assessmentId: assessmentId,
      studentId: studentId,
      studentName: studentName,
      studentUsername: studentUsername,
    ));
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (startResult) => state = state.copyWith(isLoading: false, startResult: startResult),
    );
  }

  Future<void> saveAnswers(SaveAnswersParams params) async {
    final result = await _saveAnswers(params);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) {},
    );
  }

  Future<void> submitAssessment(String submissionId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await _submitAssessment(submissionId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (_) => state = state.copyWith(
        isLoading: false,
        successMessage: 'Assessment submitted',
        startResult: null,
      ),
    );
  }

  Future<void> loadStudentResults(String submissionId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getStudentResults(submissionId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (studentResult) => state = state.copyWith(isLoading: false, studentResult: studentResult),
    );
  }

  Future<void> loadStudentResultsByAssessment(String assessmentId, String studentId) async {
    state = state.copyWith(isLoading: true, error: null);
    final submResult = await _getStudentSubmission(GetStudentSubmissionParams(
      assessmentId: assessmentId,
      studentId: studentId,
    ));
    await submResult.fold(
      (failure) async {
        state = state.copyWith(isLoading: false, error: 'Could not find your submission');
      },
      (submission) async {
        if (submission == null) {
          state = state.copyWith(isLoading: false, error: 'No submission found for this assessment');
          return;
        }
        await loadStudentResults(submission.id);
      },
    );
  }

  Future<void> loadScorePreview(String assessmentId, String studentId) async {
    ProviderLogger.instance.log('loadScorePreview() START - assessmentId: $assessmentId, studentId: $studentId');
    state = state.copyWith(isLoading: true, error: null);
    ProviderLogger.instance.log('loadScorePreview() - calling _getStudentSubmission...');
    final submissionResult = await _getStudentSubmission(
      GetStudentSubmissionParams(
        assessmentId: assessmentId,
        studentId: studentId,
      ),
    );
    ProviderLogger.instance.log('loadScorePreview() - got submissionResult, folding...');
    await submissionResult.fold(
      (failure) async {
        ProviderLogger.instance.error('loadScorePreview() FAILED', Exception(failure.message));
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (submission) async {
        ProviderLogger.instance.log('loadScorePreview() GOT SUBMISSION');
        ProviderLogger.instance.log('loadScorePreview() - submission is null: ${submission == null}');
        if (submission != null) {
          ProviderLogger.instance.log('loadScorePreview() - submission.id: ${submission.id}, isSubmitted: ${submission.isSubmitted}');
        }
        if (submission == null) {
          ProviderLogger.instance.log('loadScorePreview() NOT YET SUBMITTED (submission==null) - no results to load');
          state = state.copyWith(isLoading: false, currentStudentSubmission: null);
          return;
        }
        state = state.copyWith(isLoading: false, currentStudentSubmission: submission);
        if (!submission.isSubmitted) return;
        loadStudentResults(submission.id).then((_) {
          if (state.error != null) {
            state = state.copyWith(error: null);
          }
        }).ignore();
      },
    );
    ProviderLogger.instance.log('loadScorePreview() END - currentStudentSubmission=${state.currentStudentSubmission?.id}');
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

final studentAssessmentProvider = StateNotifierProvider<StudentAssessmentNotifier, StudentAssessmentState>((ref) {
  return StudentAssessmentNotifier(
    sl<GetAssessments>(),
    sl<GetAssessmentDetail>(),
    sl<StartAssessment>(),
    sl<SaveAnswers>(),
    sl<SubmitAssessment>(),
    sl<GetStudentResults>(),
    sl<GetStudentSubmission>(),
  );
});
