import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/domain/assessments/usecases/add_questions.dart';
import 'package:likha/domain/assessments/usecases/delete_question.dart';
import 'package:likha/domain/assessments/usecases/get_assessment_detail.dart';
import 'package:likha/domain/assessments/usecases/release_results.dart';
import 'package:likha/domain/assessments/usecases/reorder_questions.dart';
import 'package:likha/domain/assessments/usecases/update_assessment.dart';
import 'package:likha/domain/assessments/usecases/update_question.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';
import 'package:likha/injection_container.dart';
import 'assessment_utils.dart';

const _unset = Object();

class AssessmentDetailState {
  final Assessment? currentAssessment;
  final List<Question> questions;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  AssessmentDetailState({
    this.currentAssessment,
    this.questions = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  AssessmentDetailState copyWith({
    Object? currentAssessment = _unset,
    List<Question>? questions,
    bool? isLoading,
    Object? error = _unset,
    Object? successMessage = _unset,
  }) {
    return AssessmentDetailState(
      currentAssessment: identical(currentAssessment, _unset)
          ? this.currentAssessment
          : currentAssessment as Assessment?,
      questions: questions ?? this.questions,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      successMessage: identical(successMessage, _unset) ? this.successMessage : successMessage as String?,
    );
  }
}

class AssessmentDetailNotifier extends StateNotifier<AssessmentDetailState> {
  final GetAssessmentDetail _getAssessmentDetail;
  final UpdateAssessment _updateAssessment;
  final ReleaseResults _releaseResults;
  final AddQuestions _addQuestions;
  final UpdateQuestion _updateQuestion;
  final DeleteQuestion _deleteQuestion;
  final ReorderAllQuestions _reorderAllQuestions;

  AssessmentDetailNotifier(
    this._getAssessmentDetail,
    this._updateAssessment,
    this._releaseResults,
    this._addQuestions,
    this._updateQuestion,
    this._deleteQuestion,
    this._reorderAllQuestions,
  ) : super(AssessmentDetailState());

  Future<void> loadAssessmentDetail(String assessmentId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getAssessmentDetail(assessmentId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
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

  Future<void> updateAssessment(UpdateAssessmentParams params) async {
    final previousAssessment = state.currentAssessment;

    Assessment? optimistic;
    final existing = state.currentAssessment;
    if (existing != null) {
      optimistic = withUpdatedAssessment(
        existing,
        title: params.title,
        description: params.description,
        timeLimitMinutes: params.timeLimitMinutes,
        openAt: params.openAt != null ? DateTime.tryParse(params.openAt!) : null,
        closeAt: params.closeAt != null ? DateTime.tryParse(params.closeAt!) : null,
        showResultsImmediately: params.showResultsImmediately,
        termNumber: params.termNumber,
        component: params.component,
      );
      state = state.copyWith(
        error: null,
        successMessage: null,
        currentAssessment: optimistic,
      );
    } else {
      state = state.copyWith(error: null, successMessage: null);
    }

    final result = await _updateAssessment(params);
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
        currentAssessment: previousAssessment,
      ),
      (mutationResult) {
        final assessment = mutationResult.entity;
        state = state.copyWith(
          currentAssessment: assessment,
          successMessage: 'Assessment updated',
        );
        sl<GradingRepository>().findGradeItemBySourceId(params.assessmentId).then((res) {
          res.fold((_) {}, (item) {
            if (item != null) {
              final updates = <String, dynamic>{};
              if (params.title != null) updates['title'] = params.title;
              if (updates.isNotEmpty) {
                sl<GradingRepository>().updateGradeItem(id: item.id, data: updates);
              }
            }
          });
        });
      },
    );
  }

  Future<void> releaseResults(String assessmentId) async {
    final previousAssessment = state.currentAssessment;

    final existing = state.currentAssessment;
    if (existing != null) {
      final optimistic = withUpdatedAssessment(existing, resultsReleased: true);
      state = state.copyWith(
        error: null,
        successMessage: null,
        currentAssessment: optimistic,
      );
    } else {
      state = state.copyWith(error: null, successMessage: null);
    }

    final result = await _releaseResults(assessmentId);
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
        currentAssessment: previousAssessment,
      ),
      (mutationResult) {
        final assessment = mutationResult.entity;
        final current = assessment.classId.isEmpty
            ? (state.currentAssessment != null
                ? withUpdatedAssessment(state.currentAssessment!, resultsReleased: true)
                : assessment)
            : assessment;
        state = state.copyWith(
          currentAssessment: current,
          successMessage: 'Results released',
        );
      },
    );
  }

  Future<void> addQuestions(AddQuestionsParams params) async {
    final previousQuestions = state.questions;
    final previousAssessment = state.currentAssessment;
    state = state.copyWith(error: null, successMessage: null);
    final result = await _addQuestions(params);
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
        questions: previousQuestions,
        currentAssessment: previousAssessment,
      ),
      (mutationResult) {
        final questions = mutationResult.entity;
        final newCount = (state.currentAssessment?.questionCount ?? 0) + questions.length;
        final newPoints = (state.currentAssessment?.totalPoints ?? 0) +
            questions.fold<int>(0, (sum, q) => sum + q.points);
        final updatedAssessment = state.currentAssessment != null
            ? Assessment(
                id: state.currentAssessment!.id,
                classId: state.currentAssessment!.classId,
                title: state.currentAssessment!.title,
                description: state.currentAssessment!.description,
                timeLimitMinutes: state.currentAssessment!.timeLimitMinutes,
                openAt: state.currentAssessment!.openAt,
                closeAt: state.currentAssessment!.closeAt,
                showResultsImmediately: state.currentAssessment!.showResultsImmediately,
                resultsReleased: state.currentAssessment!.resultsReleased,
                isPublished: state.currentAssessment!.isPublished,
                orderIndex: state.currentAssessment!.orderIndex,
                totalPoints: newPoints,
                questionCount: newCount,
                submissionCount: state.currentAssessment!.submissionCount,
                isSubmitted: state.currentAssessment!.isSubmitted,
                tosId: state.currentAssessment!.tosId,
                termNumber: state.currentAssessment!.termNumber,
                component: state.currentAssessment!.component,
                createdAt: state.currentAssessment!.createdAt,
                updatedAt: state.currentAssessment!.updatedAt,
                cachedAt: state.currentAssessment!.cachedAt,
                syncStatus: state.currentAssessment!.syncStatus,
              )
            : null;
        state = state.copyWith(
          questions: [...state.questions, ...questions],
          currentAssessment: updatedAssessment,
          successMessage: 'Questions added',
        );
      },
    );
  }

  Future<void> updateQuestion(UpdateQuestionParams params) async {
    final previousQuestions = state.questions;
    final previousAssessment = state.currentAssessment;

    final existingQ = state.questions.where((q) => q.id == params.questionId).firstOrNull;
    if (existingQ != null) {
      final oldPoints = existingQ.points;
      final newPoints = params.data['points'] as int? ?? oldPoints;
      final optimisticQ = Question(
        id: existingQ.id,
        assessmentId: existingQ.assessmentId,
        questionType: params.data['question_type'] as String? ?? existingQ.questionType,
        questionText: params.data['question_text'] as String? ?? existingQ.questionText,
        points: newPoints,
        orderIndex: params.data['order_index'] as int? ?? existingQ.orderIndex,
        isMultiSelect: params.data['is_multi_select'] as bool? ?? existingQ.isMultiSelect,
        tosCompetencyId: existingQ.tosCompetencyId,
        cognitiveLevel: existingQ.cognitiveLevel,
        difficulty: existingQ.difficulty,
        choices: existingQ.choices,
        correctAnswers: existingQ.correctAnswers,
        enumerationItems: existingQ.enumerationItems,
        createdAt: existingQ.createdAt,
        updatedAt: DateTime.now(),
        cachedAt: existingQ.cachedAt,
        syncStatus: SyncStatus.pending,
      );
      Assessment? updatedAssessment;
      if (state.currentAssessment != null && newPoints != oldPoints) {
        final pointsDelta = newPoints - oldPoints;
        updatedAssessment = Assessment(
          id: state.currentAssessment!.id,
          classId: state.currentAssessment!.classId,
          title: state.currentAssessment!.title,
          description: state.currentAssessment!.description,
          timeLimitMinutes: state.currentAssessment!.timeLimitMinutes,
          openAt: state.currentAssessment!.openAt,
          closeAt: state.currentAssessment!.closeAt,
          showResultsImmediately: state.currentAssessment!.showResultsImmediately,
          resultsReleased: state.currentAssessment!.resultsReleased,
          isPublished: state.currentAssessment!.isPublished,
          orderIndex: state.currentAssessment!.orderIndex,
          totalPoints: state.currentAssessment!.totalPoints + pointsDelta,
          questionCount: state.currentAssessment!.questionCount,
          submissionCount: state.currentAssessment!.submissionCount,
          isSubmitted: state.currentAssessment!.isSubmitted,
          tosId: state.currentAssessment!.tosId,
          termNumber: state.currentAssessment!.termNumber,
          component: state.currentAssessment!.component,
          createdAt: state.currentAssessment!.createdAt,
          updatedAt: state.currentAssessment!.updatedAt,
          cachedAt: state.currentAssessment!.cachedAt,
          syncStatus: state.currentAssessment!.syncStatus,
        );
      }
      if (updatedAssessment != null) {
        state = state.copyWith(
          error: null,
          successMessage: null,
          questions: state.questions.map((q) => q.id == params.questionId ? optimisticQ : q).toList(),
          currentAssessment: updatedAssessment,
        );
      } else {
        state = state.copyWith(
          error: null,
          successMessage: null,
          questions: state.questions.map((q) => q.id == params.questionId ? optimisticQ : q).toList(),
        );
      }
    } else {
      state = state.copyWith(error: null, successMessage: null);
    }

    final result = await _updateQuestion(params);
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
        questions: previousQuestions,
        currentAssessment: previousAssessment,
      ),
      (mutationResult) {
        final question = mutationResult.entity;
        state = state.copyWith(
          questions: state.questions.map((q) => q.id == question.id ? question : q).toList(),
          successMessage: 'Question updated',
        );
      },
    );
  }

  Future<void> deleteQuestion(String questionId) async {
    final previousQuestions = state.questions;
    final previousAssessment = state.currentAssessment;

    final deletedQ = state.questions.where((q) => q.id == questionId).firstOrNull;
    Assessment? updatedAssessment;
    if (deletedQ != null && state.currentAssessment != null) {
      updatedAssessment = Assessment(
        id: state.currentAssessment!.id,
        classId: state.currentAssessment!.classId,
        title: state.currentAssessment!.title,
        description: state.currentAssessment!.description,
        timeLimitMinutes: state.currentAssessment!.timeLimitMinutes,
        openAt: state.currentAssessment!.openAt,
        closeAt: state.currentAssessment!.closeAt,
        showResultsImmediately: state.currentAssessment!.showResultsImmediately,
        resultsReleased: state.currentAssessment!.resultsReleased,
        isPublished: state.currentAssessment!.isPublished,
        orderIndex: state.currentAssessment!.orderIndex,
        totalPoints: state.currentAssessment!.totalPoints - deletedQ.points,
        questionCount: state.currentAssessment!.questionCount - 1,
        submissionCount: state.currentAssessment!.submissionCount,
        isSubmitted: state.currentAssessment!.isSubmitted,
        tosId: state.currentAssessment!.tosId,
        termNumber: state.currentAssessment!.termNumber,
        component: state.currentAssessment!.component,
        createdAt: state.currentAssessment!.createdAt,
        updatedAt: state.currentAssessment!.updatedAt,
        cachedAt: state.currentAssessment!.cachedAt,
        syncStatus: state.currentAssessment!.syncStatus,
      );
    }
    if (updatedAssessment != null) {
      state = state.copyWith(
        error: null,
        successMessage: null,
        questions: state.questions.where((q) => q.id != questionId).toList(),
        currentAssessment: updatedAssessment,
      );
    } else {
      state = state.copyWith(
        error: null,
        successMessage: null,
        questions: state.questions.where((q) => q.id != questionId).toList(),
      );
    }

    final result = await _deleteQuestion(questionId);
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
        questions: previousQuestions,
        currentAssessment: previousAssessment,
      ),
      (_) => state = state.copyWith(successMessage: 'Question deleted'),
    );
  }

  Future<void> reorderAllQuestions({
    required String assessmentId,
    required List<String> questionIds,
    required List<Question> orderedQuestions,
  }) async {
    final previousQuestions = state.questions;
    state = state.copyWith(questions: orderedQuestions);
    final result = await _reorderAllQuestions(assessmentId: assessmentId, questionIds: questionIds);
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
        questions: previousQuestions,
      ),
      (_) {},
    );
  }

  String? get currentError => state.error;

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

final assessmentDetailProvider = StateNotifierProvider<AssessmentDetailNotifier, AssessmentDetailState>((ref) {
  return AssessmentDetailNotifier(
    sl<GetAssessmentDetail>(),
    sl<UpdateAssessment>(),
    sl<ReleaseResults>(),
    sl<AddQuestions>(),
    sl<UpdateQuestion>(),
    sl<DeleteQuestion>(),
    sl<ReorderAllQuestions>(),
  );
});
