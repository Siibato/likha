import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assessments/usecases/get_submission_detail.dart';
import 'package:likha/domain/assessments/usecases/get_submissions.dart';
import 'package:likha/domain/assessments/usecases/grade_essay.dart';
import 'package:likha/domain/assessments/usecases/override_answer.dart';
import 'package:likha/injection_container.dart';

const _unset = Object();

class SubmissionReviewState {
  final List<SubmissionSummary> submissions;
  final SubmissionDetail? currentSubmission;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  SubmissionReviewState({
    this.submissions = const [],
    this.currentSubmission,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  SubmissionReviewState copyWith({
    List<SubmissionSummary>? submissions,
    Object? currentSubmission = _unset,
    bool? isLoading,
    Object? error = _unset,
    Object? successMessage = _unset,
  }) {
    return SubmissionReviewState(
      submissions: submissions ?? this.submissions,
      currentSubmission: identical(currentSubmission, _unset)
          ? this.currentSubmission
          : currentSubmission as SubmissionDetail?,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      successMessage: identical(successMessage, _unset) ? this.successMessage : successMessage as String?,
    );
  }
}

class SubmissionReviewNotifier extends StateNotifier<SubmissionReviewState> {
  final GetSubmissions _getSubmissions;
  final GetSubmissionDetail _getSubmissionDetail;
  final OverrideAnswer _overrideAnswer;
  final GradeEssay _gradeEssay;

  String? _currentAssessmentId;
  String? _currentSubmissionId;

  SubmissionReviewNotifier(
    this._getSubmissions,
    this._getSubmissionDetail,
    this._overrideAnswer,
    this._gradeEssay,
  ) : super(SubmissionReviewState());

  Future<void> loadSubmissions(String assessmentId) async {
    if (_currentAssessmentId != assessmentId) {
      _currentAssessmentId = assessmentId;
      state = state.copyWith(
        isLoading: true,
        error: null,
        submissions: [],
        currentSubmission: null,
      );
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }
    final result = await _getSubmissions(assessmentId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (submissions) => state = state.copyWith(isLoading: false, submissions: submissions),
    );
  }

  Future<void> loadSubmissionDetail(String submissionId, {bool skipBackgroundRefresh = false}) async {
    RepoLogger.instance.log('SubmissionReviewNotifier.loadSubmissionDetail: START $submissionId');
    if (_currentSubmissionId != submissionId) {
      _currentSubmissionId = submissionId;
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentSubmission: null,
      );
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }
    final result = await _getSubmissionDetail(submissionId, skipBackgroundRefresh: skipBackgroundRefresh);
    result.fold(
      (failure) {
        RepoLogger.instance.log('SubmissionReviewNotifier.loadSubmissionDetail: FAILURE $submissionId - ${failure.message}');
        state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure));
      },
      (detail) {
        if (detail == null) {
          if (skipBackgroundRefresh) {
            RepoLogger.instance.log('SubmissionReviewNotifier.loadSubmissionDetail: FETCH FAILED $submissionId');
            state = state.copyWith(isLoading: false, error: 'Failed to load submission. Check your connection and try again.');
          } else {
            RepoLogger.instance.log('SubmissionReviewNotifier.loadSubmissionDetail: CACHE MISS $submissionId - background fetch started');
          }
          return;
        }
        RepoLogger.instance.log('SubmissionReviewNotifier.loadSubmissionDetail: SUCCESS $submissionId - answers=${detail.answers.length}');
        state = state.copyWith(isLoading: false, currentSubmission: detail);
      },
    );
  }

  Future<void> overrideAnswer(OverrideAnswerParams params) async {
    final previousSubmission = state.currentSubmission;
    state = state.copyWith(error: null, successMessage: null);

    if (previousSubmission != null) {
      final updatedAnswers = previousSubmission.answers.map((answer) {
        if (answer.id == params.answerId) {
          final newPointsAwarded = params.points ?? (params.isCorrect ? answer.points.toDouble() : 0.0);
          return SubmissionAnswer(
            id: answer.id,
            questionId: answer.questionId,
            questionText: answer.questionText,
            questionType: answer.questionType,
            points: answer.points,
            answerText: answer.answerText,
            selectedChoices: answer.selectedChoices,
            enumerationAnswers: answer.enumerationAnswers,
            isAutoCorrect: answer.isAutoCorrect,
            isOverrideCorrect: params.isCorrect,
            pointsAwarded: newPointsAwarded,
            isPendingEssayGrade: answer.isPendingEssayGrade,
          );
        }
        return answer;
      }).toList();

      final newFinalScore = updatedAnswers.fold(0.0, (sum, a) => sum + a.pointsAwarded);

      state = state.copyWith(
        currentSubmission: SubmissionDetail(
          id: previousSubmission.id,
          assessmentId: previousSubmission.assessmentId,
          studentId: previousSubmission.studentId,
          studentName: previousSubmission.studentName,
          startedAt: previousSubmission.startedAt,
          submittedAt: previousSubmission.submittedAt,
          autoScore: previousSubmission.autoScore,
          finalScore: newFinalScore,
          isSubmitted: previousSubmission.isSubmitted,
          totalPoints: previousSubmission.totalPoints,
          answers: updatedAnswers,
        ),
      );
    }

    final result = await _overrideAnswer(params);
    result.fold(
      (failure) {
        state = state.copyWith(
          error: AppErrorMapper.fromFailure(failure),
          currentSubmission: previousSubmission,
        );
      },
      (_) {
        state = state.copyWith(successMessage: 'Grade overridden');
      },
    );
  }

  Future<void> gradeEssayAnswer(GradeEssayParams params) async {
    final previousSubmission = state.currentSubmission;
    state = state.copyWith(error: null, successMessage: null);

    if (previousSubmission != null) {
      final updatedAnswers = previousSubmission.answers.map((answer) {
        if (answer.id == params.answerId) {
          return SubmissionAnswer(
            id: answer.id,
            questionId: answer.questionId,
            questionText: answer.questionText,
            questionType: answer.questionType,
            points: answer.points,
            answerText: answer.answerText,
            selectedChoices: answer.selectedChoices,
            enumerationAnswers: answer.enumerationAnswers,
            isAutoCorrect: answer.isAutoCorrect,
            isOverrideCorrect: answer.isOverrideCorrect,
            pointsAwarded: params.points,
            isPendingEssayGrade: false,
          );
        }
        return answer;
      }).toList();

      final newFinalScore = updatedAnswers.fold(0.0, (sum, a) => sum + a.pointsAwarded);

      state = state.copyWith(
        currentSubmission: SubmissionDetail(
          id: previousSubmission.id,
          assessmentId: previousSubmission.assessmentId,
          studentId: previousSubmission.studentId,
          studentName: previousSubmission.studentName,
          startedAt: previousSubmission.startedAt,
          submittedAt: previousSubmission.submittedAt,
          autoScore: previousSubmission.autoScore,
          finalScore: newFinalScore,
          isSubmitted: previousSubmission.isSubmitted,
          totalPoints: previousSubmission.totalPoints,
          answers: updatedAnswers,
        ),
      );
    }

    final result = await _gradeEssay(params);
    result.fold(
      (failure) {
        state = state.copyWith(
          error: AppErrorMapper.fromFailure(failure),
          currentSubmission: previousSubmission,
        );
      },
      (_) {
        state = state.copyWith(successMessage: 'Essay graded');
      },
    );
  }

  String? get currentError => state.error;

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }

  @override
  void dispose() {
    _currentAssessmentId = null;
    _currentSubmissionId = null;
    super.dispose();
  }
}

final submissionReviewProvider = StateNotifierProvider<SubmissionReviewNotifier, SubmissionReviewState>((ref) {
  return SubmissionReviewNotifier(
    sl<GetSubmissions>(),
    sl<GetSubmissionDetail>(),
    sl<OverrideAnswer>(),
    sl<GradeEssay>(),
  );
});
