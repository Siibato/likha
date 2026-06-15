import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assessments/usecases/add_questions.dart';
import 'package:likha/domain/assessments/usecases/create_assessment.dart';
import 'package:likha/domain/assessments/usecases/delete_assessment.dart';
import 'package:likha/domain/assessments/usecases/delete_question.dart';
import 'package:likha/domain/assessments/usecases/get_assessment_detail.dart';
import 'package:likha/domain/assessments/usecases/get_assessments.dart';
import 'package:likha/domain/assessments/usecases/get_statistics.dart';
import 'package:likha/domain/assessments/usecases/get_submission_detail.dart';
import 'package:likha/domain/assessments/usecases/get_submissions.dart';
import 'package:likha/domain/assessments/usecases/grade_essay.dart';
import 'package:likha/domain/assessments/usecases/override_answer.dart';
import 'package:likha/domain/assessments/usecases/publish_assessment.dart';
import 'package:likha/domain/assessments/usecases/release_results.dart';
import 'package:likha/domain/assessments/usecases/reorder_assessment.dart';
import 'package:likha/domain/assessments/usecases/reorder_questions.dart';
import 'package:likha/domain/assessments/usecases/unpublish_assessment.dart';
import 'package:likha/domain/assessments/usecases/update_assessment.dart';
import 'package:likha/domain/assessments/usecases/update_question.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';
import 'package:likha/injection_container.dart';

const _unset = Object();

class TeacherAssessmentState {
  final List<Assessment> assessments;
  final Assessment? currentAssessment;
  final List<Question> questions;
  final List<SubmissionSummary> submissions;
  final SubmissionDetail? currentSubmission;
  final AssessmentStatistics? statistics;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  TeacherAssessmentState({
    this.assessments = const [],
    this.currentAssessment,
    this.questions = const [],
    this.submissions = const [],
    this.currentSubmission,
    this.statistics,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  TeacherAssessmentState copyWith({
    List<Assessment>? assessments,
    Object? currentAssessment = _unset,
    List<Question>? questions,
    List<SubmissionSummary>? submissions,
    Object? currentSubmission = _unset,
    Object? statistics = _unset,
    bool? isLoading,
    Object? error = _unset,
    Object? successMessage = _unset,
  }) {
    return TeacherAssessmentState(
      assessments: assessments ?? this.assessments,
      currentAssessment: identical(currentAssessment, _unset) ? this.currentAssessment : currentAssessment as Assessment?,
      questions: questions ?? this.questions,
      submissions: submissions ?? this.submissions,
      currentSubmission: identical(currentSubmission, _unset) ? this.currentSubmission : currentSubmission as SubmissionDetail?,
      statistics: identical(statistics, _unset) ? this.statistics : statistics as AssessmentStatistics?,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      successMessage: identical(successMessage, _unset) ? this.successMessage : successMessage as String?,
    );
  }
}

class TeacherAssessmentNotifier extends StateNotifier<TeacherAssessmentState> {
  final CreateAssessment _createAssessment;
  final GetAssessments _getAssessments;
  final GetAssessmentDetail _getAssessmentDetail;
  final PublishAssessment _publishAssessment;
  final UnpublishAssessment _unpublishAssessment;
  final DeleteAssessment _deleteAssessment;
  final AddQuestions _addQuestions;
  final GetSubmissions _getSubmissions;
  final GetSubmissionDetail _getSubmissionDetail;
  final OverrideAnswer _overrideAnswer;
  final GradeEssay _gradeEssay;
  final ReleaseResults _releaseResults;
  final GetStatistics _getStatistics;
  final UpdateAssessment _updateAssessment;
  final UpdateQuestion _updateQuestion;
  final DeleteQuestion _deleteQuestion;
  final ReorderAllQuestions _reorderAllQuestions;
  final ReorderAllAssessments _reorderAllAssessments;

  String? _currentClassId;
  String? _currentAssessmentId;
  String? _currentSubmissionId;

  Assessment _withUpdatedAssessment(
    Assessment a, {
    bool? isPublished,
    bool? resultsReleased,
    String? title,
    String? description,
    int? timeLimitMinutes,
    DateTime? openAt,
    DateTime? closeAt,
    bool? showResultsImmediately,
    int? gradingPeriodNumber,
    String? component,
  }) {
    return Assessment(
      id: a.id,
      classId: a.classId,
      title: title ?? a.title,
      description: description ?? a.description,
      timeLimitMinutes: timeLimitMinutes ?? a.timeLimitMinutes,
      openAt: openAt ?? a.openAt,
      closeAt: closeAt ?? a.closeAt,
      showResultsImmediately: showResultsImmediately ?? a.showResultsImmediately,
      resultsReleased: resultsReleased ?? a.resultsReleased,
      isPublished: isPublished ?? a.isPublished,
      orderIndex: a.orderIndex,
      totalPoints: a.totalPoints,
      questionCount: a.questionCount,
      submissionCount: a.submissionCount,
      isSubmitted: a.isSubmitted,
      tosId: a.tosId,
      gradingPeriodNumber: gradingPeriodNumber ?? a.gradingPeriodNumber,
      component: component ?? a.component,
      createdAt: a.createdAt,
      updatedAt: DateTime.now(),
      cachedAt: a.cachedAt,
      syncStatus: SyncStatus.pending,
    );
  }

  late StreamSubscription<String?> _refreshSub;

  TeacherAssessmentNotifier(
    this._createAssessment,
    this._getAssessments,
    this._getAssessmentDetail,
    this._publishAssessment,
    this._unpublishAssessment,
    this._deleteAssessment,
    this._addQuestions,
    this._getSubmissions,
    this._getSubmissionDetail,
    this._overrideAnswer,
    this._gradeEssay,
    this._releaseResults,
    this._getStatistics,
    this._updateAssessment,
    this._updateQuestion,
    this._deleteQuestion,
    this._reorderAllQuestions,
    this._reorderAllAssessments,
  ) : super(TeacherAssessmentState()) {
    _refreshSub = sl<DataEventBus>().onAssessmentsChanged.listen((classId) {
      if (_currentClassId != null && _currentClassId == classId) {
        loadAssessments(_currentClassId!, skipBackgroundRefresh: true);
      }
    });
  }

  Future<void> loadAssessments(String classId, {bool publishedOnly = false, bool skipBackgroundRefresh = false}) async {
    _currentClassId = classId;
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getAssessments(classId, publishedOnly: publishedOnly, skipBackgroundRefresh: skipBackgroundRefresh);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (assessments) => state = state.copyWith(isLoading: false, assessments: assessments),
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

  Future<Assessment?> createAssessment(CreateAssessmentParams params) async {
    final previousAssessments = state.assessments;
    final previousCurrentAssessment = state.currentAssessment;
    state = state.copyWith(error: null, successMessage: null);
    final result = await _createAssessment(params);
    return result.fold<Assessment?>(
      (failure) {
        state = state.copyWith(
          error: AppErrorMapper.fromFailure(failure),
          assessments: previousAssessments,
          currentAssessment: previousCurrentAssessment,
        );
        return null;
      },
      (mutationResult) {
        final assessment = mutationResult.entity;
        state = state.copyWith(
          assessments: [assessment, ...state.assessments],
          currentAssessment: assessment,
          successMessage: 'Assessment created',
        );
        // Auto-create linked grade item when component + gradingPeriodNumber are set
        if (assessment.component != null && assessment.gradingPeriodNumber != null) {
          sl<GradingRepository>().createGradeItem(
            classId: params.classId,
            data: {
              'title': assessment.title,
              'component': _toGradeComponent(assessment.component!),
              'grading_period_number': assessment.gradingPeriodNumber!,
              'total_points': assessment.totalPoints.toDouble(),
              'source_type': 'assessment',
              'source_id': assessment.id,
              'order_index': 0,
            },
          );
        }
        return assessment;
      },
    );
  }

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

  Future<void> publishAssessment(String assessmentId) async {
    final previousAssessments = state.assessments;
    final previousCurrentAssessment = state.currentAssessment;

    final existing = state.currentAssessment?.id == assessmentId
        ? state.currentAssessment
        : state.assessments.where((a) => a.id == assessmentId).firstOrNull;
    if (existing != null) {
      final optimistic = _withUpdatedAssessment(existing, isPublished: true);
      state = state.copyWith(
        error: null,
        successMessage: null,
        currentAssessment: optimistic,
        assessments: state.assessments
            .map((a) => a.id == assessmentId ? optimistic : a)
            .toList(),
      );
    } else {
      state = state.copyWith(error: null, successMessage: null);
    }

    final result = await _publishAssessment(assessmentId);
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
        assessments: previousAssessments,
        currentAssessment: previousCurrentAssessment,
      ),
      (mutationResult) {
        final assessment = mutationResult.entity;
        final updatedList = assessment.classId.isEmpty
            ? state.assessments
                .map((a) => a.id == assessmentId
                    ? _withUpdatedAssessment(a, isPublished: true)
                    : a)
                .toList()
            : state.assessments.map((a) => a.id == assessmentId ? assessment : a).toList();
        final current = assessment.classId.isEmpty
            ? (state.currentAssessment?.id == assessmentId && state.currentAssessment != null
                ? _withUpdatedAssessment(state.currentAssessment!, isPublished: true)
                : assessment)
            : assessment;
        state = state.copyWith(
          currentAssessment: current,
          assessments: updatedList,
          successMessage: 'Assessment published',
        );
      },
    );
  }

  Future<void> unpublishAssessment(String assessmentId) async {
    final previousAssessments = state.assessments;
    final previousCurrentAssessment = state.currentAssessment;

    final existing = state.currentAssessment?.id == assessmentId
        ? state.currentAssessment
        : state.assessments.where((a) => a.id == assessmentId).firstOrNull;
    if (existing != null) {
      final optimistic = _withUpdatedAssessment(existing, isPublished: false);
      state = state.copyWith(
        error: null,
        successMessage: null,
        currentAssessment: optimistic,
        assessments: state.assessments
            .map((a) => a.id == assessmentId ? optimistic : a)
            .toList(),
      );
    } else {
      state = state.copyWith(error: null, successMessage: null);
    }

    final result = await _unpublishAssessment(assessmentId);
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
        assessments: previousAssessments,
        currentAssessment: previousCurrentAssessment,
      ),
      (mutationResult) {
        final assessment = mutationResult.entity;
        final updatedList = assessment.classId.isEmpty
            ? state.assessments
                .map((a) => a.id == assessmentId
                    ? _withUpdatedAssessment(a, isPublished: false)
                    : a)
                .toList()
            : state.assessments.map((a) => a.id == assessmentId ? assessment : a).toList();
        final current = assessment.classId.isEmpty
            ? (state.currentAssessment?.id == assessmentId && state.currentAssessment != null
                ? _withUpdatedAssessment(state.currentAssessment!, isPublished: false)
                : assessment)
            : assessment;
        state = state.copyWith(
          currentAssessment: current,
          assessments: updatedList,
          successMessage: 'Assessment moved to draft',
        );
      },
    );
  }

  Future<void> deleteAssessment(String assessmentId) async {
    final previousAssessments = state.assessments;
    final previousCurrentAssessment = state.currentAssessment;
    state = state.copyWith(
      error: null,
      successMessage: null,
      assessments: state.assessments.where((a) => a.id != assessmentId).toList(),
      currentAssessment: null,
    );
    final result = await _deleteAssessment(assessmentId);
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
        assessments: previousAssessments,
        currentAssessment: previousCurrentAssessment,
      ),
      (_) {
        state = state.copyWith(
          successMessage: 'Assessment deleted',
        );
        // Delete linked grade item if one exists
        sl<GradingRepository>().findGradeItemBySourceId(assessmentId).then((res) {
          res.fold((_) {}, (item) {
            if (item != null) {
              sl<GradingRepository>().deleteGradeItem(id: item.id);
            }
          });
        });
      },
    );
  }

  Future<void> reorderAllAssessments({
    required String classId,
    required List<String> assessmentIds,
    required List<Assessment> orderedAssessments,
  }) async {
    final previousAssessments = state.assessments;
    state = state.copyWith(assessments: orderedAssessments);
    final result = await _reorderAllAssessments(classId: classId, assessmentIds: assessmentIds);
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
        assessments: previousAssessments,
      ),
      (_) {},
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

  Future<void> addQuestions(AddQuestionsParams params) async {
    final previousQuestions = state.questions;
    final previousCurrentAssessment = state.currentAssessment;
    state = state.copyWith(error: null, successMessage: null);
    final result = await _addQuestions(params);
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
        questions: previousQuestions,
        currentAssessment: previousCurrentAssessment,
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
                gradingPeriodNumber: state.currentAssessment!.gradingPeriodNumber,
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

  Future<void> updateAssessment(UpdateAssessmentParams params) async {
    final previousAssessments = state.assessments;
    final previousCurrentAssessment = state.currentAssessment;

    Assessment? optimistic;
    final existing = state.currentAssessment?.id == params.assessmentId
        ? state.currentAssessment
        : state.assessments.where((a) => a.id == params.assessmentId).firstOrNull;
    if (existing != null) {
      optimistic = _withUpdatedAssessment(
        existing,
        title: params.title,
        description: params.description,
        timeLimitMinutes: params.timeLimitMinutes,
        openAt: params.openAt != null ? DateTime.tryParse(params.openAt!) : null,
        closeAt: params.closeAt != null ? DateTime.tryParse(params.closeAt!) : null,
        showResultsImmediately: params.showResultsImmediately,
        gradingPeriodNumber: params.gradingPeriodNumber,
        component: params.component,
      );
      state = state.copyWith(
        error: null,
        successMessage: null,
        currentAssessment: optimistic,
        assessments: state.assessments
            .map((a) => a.id == params.assessmentId ? optimistic! : a)
            .toList(),
      );
    } else {
      state = state.copyWith(error: null, successMessage: null);
    }

    final result = await _updateAssessment(params);
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
        assessments: previousAssessments,
        currentAssessment: previousCurrentAssessment,
      ),
      (mutationResult) {
        final assessment = mutationResult.entity;
        state = state.copyWith(
          currentAssessment: assessment,
          assessments: state.assessments
              .map((a) => a.id == params.assessmentId ? assessment : a)
              .toList(),
          successMessage: 'Assessment updated',
        );
        // Sync title to linked grade item if one exists
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

  Future<void> updateQuestion(UpdateQuestionParams params) async {
    final previousQuestions = state.questions;
    final previousCurrentAssessment = state.currentAssessment;

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
          gradingPeriodNumber: state.currentAssessment!.gradingPeriodNumber,
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
        currentAssessment: previousCurrentAssessment,
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
    final previousCurrentAssessment = state.currentAssessment;

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
        gradingPeriodNumber: state.currentAssessment!.gradingPeriodNumber,
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
        currentAssessment: previousCurrentAssessment,
      ),
      (_) => state = state.copyWith(
        successMessage: 'Question deleted',
      ),
    );
  }

  Future<void> releaseResults(String assessmentId) async {
    final previousAssessments = state.assessments;
    final previousCurrentAssessment = state.currentAssessment;

    final existing = state.currentAssessment?.id == assessmentId
        ? state.currentAssessment
        : state.assessments.where((a) => a.id == assessmentId).firstOrNull;
    if (existing != null) {
      final optimistic = _withUpdatedAssessment(existing, resultsReleased: true);
      state = state.copyWith(
        error: null,
        successMessage: null,
        currentAssessment: optimistic,
        assessments: state.assessments
            .map((a) => a.id == assessmentId ? optimistic : a)
            .toList(),
      );
    } else {
      state = state.copyWith(error: null, successMessage: null);
    }

    final result = await _releaseResults(assessmentId);
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
        assessments: previousAssessments,
        currentAssessment: previousCurrentAssessment,
      ),
      (mutationResult) {
        final assessment = mutationResult.entity;
        final updatedList = assessment.classId.isEmpty
            ? state.assessments
                .map((a) => a.id == assessmentId
                    ? _withUpdatedAssessment(a, resultsReleased: true)
                    : a)
                .toList()
            : state.assessments.map((a) => a.id == assessmentId ? assessment : a).toList();
        final current = assessment.classId.isEmpty
            ? (state.currentAssessment?.id == assessmentId && state.currentAssessment != null
                ? _withUpdatedAssessment(state.currentAssessment!, resultsReleased: true)
                : assessment)
            : assessment;
        state = state.copyWith(
          currentAssessment: current,
          assessments: updatedList,
          successMessage: 'Results released',
        );
      },
    );
  }

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

  Future<void> loadSubmissionDetail(String submissionId) async {
    RepoLogger.instance.log('TeacherAssessmentNotifier.loadSubmissionDetail: START $submissionId');
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
    final result = await _getSubmissionDetail(submissionId);
    result.fold(
      (failure) {
        RepoLogger.instance.log('TeacherAssessmentNotifier.loadSubmissionDetail: FAILURE $submissionId - ${failure.message}');
        state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure));
      },
      (detail) {
        RepoLogger.instance.log('TeacherAssessmentNotifier.loadSubmissionDetail: SUCCESS $submissionId - answers=${detail.answers.length}');
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
        state = state.copyWith(
          successMessage: 'Grade overridden',
        );
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
        state = state.copyWith(
          successMessage: 'Essay graded',
        );
      },
    );
  }

  Future<void> loadStatistics(String assessmentId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getStatistics(assessmentId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (stats) => state = state.copyWith(isLoading: false, statistics: stats),
    );
  }

  String? get currentError => state.error;

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }

  @override
  void dispose() {
    _refreshSub.cancel();
    _currentAssessmentId = null;
    _currentSubmissionId = null;
    super.dispose();
  }
}

final teacherAssessmentProvider = StateNotifierProvider<TeacherAssessmentNotifier, TeacherAssessmentState>((ref) {
  return TeacherAssessmentNotifier(
    sl<CreateAssessment>(),
    sl<GetAssessments>(),
    sl<GetAssessmentDetail>(),
    sl<PublishAssessment>(),
    sl<UnpublishAssessment>(),
    sl<DeleteAssessment>(),
    sl<AddQuestions>(),
    sl<GetSubmissions>(),
    sl<GetSubmissionDetail>(),
    sl<OverrideAnswer>(),
    sl<GradeEssay>(),
    sl<ReleaseResults>(),
    sl<GetStatistics>(),
    sl<UpdateAssessment>(),
    sl<UpdateQuestion>(),
    sl<DeleteQuestion>(),
    sl<ReorderAllQuestions>(),
    sl<ReorderAllAssessments>(),
  );
});
