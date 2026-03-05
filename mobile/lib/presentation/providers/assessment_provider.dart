import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assessments/usecases/add_questions.dart';
import 'package:likha/domain/assessments/usecases/create_assessment.dart';
import 'package:likha/domain/assessments/usecases/delete_assessment.dart';
import 'package:likha/domain/assessments/usecases/get_assessment_detail.dart';
import 'package:likha/domain/assessments/usecases/get_assessments.dart';
import 'package:likha/domain/assessments/usecases/get_statistics.dart';
import 'package:likha/domain/assessments/usecases/get_student_results.dart';
import 'package:likha/domain/assessments/usecases/get_submission_detail.dart';
import 'package:likha/domain/assessments/usecases/get_submissions.dart';
import 'package:likha/domain/assessments/usecases/override_answer.dart';
import 'package:likha/domain/assessments/usecases/publish_assessment.dart';
import 'package:likha/domain/assessments/usecases/release_results.dart';
import 'package:likha/domain/assessments/usecases/save_answers.dart';
import 'package:likha/domain/assessments/usecases/start_assessment.dart';
import 'package:likha/domain/assessments/usecases/submit_assessment.dart';
import 'package:likha/domain/assessments/usecases/update_assessment.dart';
import 'package:likha/domain/assessments/usecases/update_question.dart';
import 'package:likha/domain/assessments/usecases/delete_question.dart';
import 'package:likha/injection_container.dart';

class AssessmentState {
  final List<Assessment> assessments;
  final Assessment? currentAssessment;
  final List<Question> questions;
  final List<SubmissionSummary> submissions;
  final SubmissionDetail? currentSubmission;
  final StartSubmissionResult? startResult;
  final StudentResult? studentResult;
  final AssessmentStatistics? statistics;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  AssessmentState({
    this.assessments = const [],
    this.currentAssessment,
    this.questions = const [],
    this.submissions = const [],
    this.currentSubmission,
    this.startResult,
    this.studentResult,
    this.statistics,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  AssessmentState copyWith({
    List<Assessment>? assessments,
    Assessment? currentAssessment,
    List<Question>? questions,
    List<SubmissionSummary>? submissions,
    SubmissionDetail? currentSubmission,
    StartSubmissionResult? startResult,
    StudentResult? studentResult,
    AssessmentStatistics? statistics,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearAssessment = false,
    bool clearSubmission = false,
    bool clearStartResult = false,
    bool clearStudentResult = false,
    bool clearStatistics = false,
  }) {
    return AssessmentState(
      assessments: assessments ?? this.assessments,
      currentAssessment: clearAssessment
          ? null
          : (currentAssessment ?? this.currentAssessment),
      questions: questions ?? this.questions,
      submissions: submissions ?? this.submissions,
      currentSubmission: clearSubmission
          ? null
          : (currentSubmission ?? this.currentSubmission),
      startResult:
          clearStartResult ? null : (startResult ?? this.startResult),
      studentResult:
          clearStudentResult ? null : (studentResult ?? this.studentResult),
      statistics: clearStatistics ? null : (statistics ?? this.statistics),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class AssessmentNotifier extends StateNotifier<AssessmentState> {
  final CreateAssessment _createAssessment;
  final GetAssessments _getAssessments;
  final GetAssessmentDetail _getAssessmentDetail;
  final PublishAssessment _publishAssessment;
  final DeleteAssessment _deleteAssessment;
  final AddQuestions _addQuestions;
  final GetSubmissions _getSubmissions;
  final GetSubmissionDetail _getSubmissionDetail;
  final OverrideAnswer _overrideAnswer;
  final ReleaseResults _releaseResults;
  final GetStatistics _getStatistics;
  final StartAssessment _startAssessment;
  final SaveAnswers _saveAnswers;
  final SubmitAssessment _submitAssessment;
  final GetStudentResults _getStudentResults;
  final UpdateAssessment _updateAssessment;
  final UpdateQuestion _updateQuestion;
  final DeleteQuestion _deleteQuestion;

  String? _currentClassId;
  late StreamSubscription<String?> _refreshSub;

  AssessmentNotifier(
    this._createAssessment,
    this._getAssessments,
    this._getAssessmentDetail,
    this._publishAssessment,
    this._deleteAssessment,
    this._addQuestions,
    this._getSubmissions,
    this._getSubmissionDetail,
    this._overrideAnswer,
    this._releaseResults,
    this._getStatistics,
    this._startAssessment,
    this._saveAnswers,
    this._submitAssessment,
    this._getStudentResults,
    this._updateAssessment,
    this._updateQuestion,
    this._deleteQuestion,
  ) : super(AssessmentState()) {
    _refreshSub = sl<DataEventBus>().onAssessmentsChanged.listen((classId) {
      // Only reload if this notifier is currently showing that classId
      if (_currentClassId != null && _currentClassId == classId) {
        loadAssessments(_currentClassId!);
      }
    });
  }

  Future<void> loadAssessments(String classId) async {
    _currentClassId = classId;
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getAssessments(classId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (assessments) =>
          state = state.copyWith(isLoading: false, assessments: assessments),
    );
  }

  Future<Assessment?> createAssessment(CreateAssessmentParams params) async {
    final completer = Completer<Assessment?>();

    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _createAssessment(params);

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        completer.complete(null);
      },
      (assessment) {
        state = state.copyWith(
          isLoading: false,
          assessments: [assessment, ...state.assessments],
          currentAssessment: assessment,
          successMessage: 'Assessment created',
        );
        completer.complete(assessment);
      },
    );

    return completer.future;
  }

  Future<void> loadAssessmentDetail(String assessmentId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getAssessmentDetail(assessmentId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (data) {
        final (assessment, questions) = data;
        state = state.copyWith(
          isLoading: false,
          currentAssessment: assessment,
          questions: questions,
        );
      },
    );
  }

  Future<void> publishAssessment(String assessmentId) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _publishAssessment(assessmentId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (assessment) => state = state.copyWith(
        isLoading: false,
        currentAssessment: assessment,
        successMessage: 'Assessment published',
      ),
    );
  }

  Future<void> deleteAssessment(String assessmentId) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _deleteAssessment(assessmentId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (_) {
        state = state.copyWith(
          isLoading: false,
          assessments:
              state.assessments.where((a) => a.id != assessmentId).toList(),
          successMessage: 'Assessment deleted',
          clearAssessment: true,
        );
      },
    );
  }

  Future<void> addQuestions(AddQuestionsParams params) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _addQuestions(params);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (questions) => state = state.copyWith(
        isLoading: false,
        questions: [...state.questions, ...questions],
        successMessage: 'Questions added',
      ),
    );
  }

  Future<void> updateAssessment(UpdateAssessmentParams params) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _updateAssessment(params);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (assessment) => state = state.copyWith(
        isLoading: false,
        currentAssessment: assessment,
        successMessage: 'Assessment updated',
      ),
    );
  }

  Future<void> updateQuestion(UpdateQuestionParams params) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _updateQuestion(params);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (question) => state = state.copyWith(
        isLoading: false,
        successMessage: 'Question updated',
      ),
    );
  }

  Future<void> deleteQuestion(String questionId) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _deleteQuestion(questionId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (_) => state = state.copyWith(
        isLoading: false,
        successMessage: 'Question deleted',
      ),
    );
  }

  Future<void> releaseResults(String assessmentId) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _releaseResults(assessmentId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (assessment) => state = state.copyWith(
        isLoading: false,
        currentAssessment: assessment,
        successMessage: 'Results released',
      ),
    );
  }

  // Teacher: Submissions
  Future<void> loadSubmissions(String assessmentId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getSubmissions(assessmentId);
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
      (detail) => state =
          state.copyWith(isLoading: false, currentSubmission: detail),
    );
  }

  Future<void> overrideAnswer(OverrideAnswerParams params) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _overrideAnswer(params);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (_) => state = state.copyWith(
        isLoading: false,
        successMessage: 'Grade overridden',
      ),
    );
  }

  Future<void> loadStatistics(String assessmentId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getStatistics(assessmentId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (stats) =>
          state = state.copyWith(isLoading: false, statistics: stats),
    );
  }

  // Student
  Future<void> startAssessment(
    String assessmentId,
    String studentId,
    String studentName,
    String studentUsername,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _startAssessment(StartAssessmentParams(
      assessmentId:    assessmentId,
      studentId:       studentId,
      studentName:     studentName,
      studentUsername: studentUsername,
    ));
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (startResult) =>
          state = state.copyWith(isLoading: false, startResult: startResult),
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
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _submitAssessment(submissionId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (_) => state = state.copyWith(
        isLoading: false,
        successMessage: 'Assessment submitted',
        clearStartResult: true,
      ),
    );
  }

  Future<void> loadStudentResults(String submissionId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getStudentResults(submissionId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (studentResult) =>
          state = state.copyWith(isLoading: false, studentResult: studentResult),
    );
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  @override
  void dispose() {
    _refreshSub.cancel();
    super.dispose();
  }
}

final assessmentProvider =
    StateNotifierProvider<AssessmentNotifier, AssessmentState>((ref) {
  return AssessmentNotifier(
    sl<CreateAssessment>(),
    sl<GetAssessments>(),
    sl<GetAssessmentDetail>(),
    sl<PublishAssessment>(),
    sl<DeleteAssessment>(),
    sl<AddQuestions>(),
    sl<GetSubmissions>(),
    sl<GetSubmissionDetail>(),
    sl<OverrideAnswer>(),
    sl<ReleaseResults>(),
    sl<GetStatistics>(),
    sl<StartAssessment>(),
    sl<SaveAnswers>(),
    sl<SubmitAssessment>(),
    sl<GetStudentResults>(),
    sl<UpdateAssessment>(),
    sl<UpdateQuestion>(),
    sl<DeleteQuestion>(),
  );
});
