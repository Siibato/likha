import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
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
    final completer = Completer<Assessment?>();
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await _createAssessment(params);
    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure));
        completer.complete(null);
      },
      (assessment) {
        state = state.copyWith(
          isLoading: false,
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
              'is_departmental_exam': params.isDepartmentalExam ?? false,
              'source_type': 'assessment',
              'source_id': assessment.id,
              'order_index': 0,
            },
          );
        }
        completer.complete(assessment);
      },
    );
    return completer.future;
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
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await _publishAssessment(assessmentId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (assessment) {
        final updatedList = assessment.classId.isEmpty
            ? state.assessments.map((a) {
                if (a.id == assessmentId) {
                  return Assessment(
                    id: a.id,
                    classId: a.classId,
                    title: a.title,
                    description: a.description,
                    timeLimitMinutes: a.timeLimitMinutes,
                    openAt: a.openAt,
                    closeAt: a.closeAt,
                    showResultsImmediately: a.showResultsImmediately,
                    resultsReleased: a.resultsReleased,
                    isPublished: true,
                    orderIndex: a.orderIndex,
                    totalPoints: a.totalPoints,
                    questionCount: a.questionCount,
                    submissionCount: a.submissionCount,
                    gradingPeriodNumber: a.gradingPeriodNumber,
                    component: a.component,
                    createdAt: a.createdAt,
                    updatedAt: DateTime.now(),
                    needsSync: true,
                    cachedAt: DateTime.now(),
                  );
                }
                return a;
              }).toList()
            : state.assessments.map((a) => a.id == assessmentId ? assessment : a).toList();
        state = state.copyWith(
          isLoading: false,
          currentAssessment: assessment,
          assessments: updatedList,
          successMessage: 'Assessment published',
        );
      },
    );
  }

  Future<void> unpublishAssessment(String assessmentId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await _unpublishAssessment(assessmentId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (assessment) {
        final updatedList = assessment.classId.isEmpty
            ? state.assessments.map((a) {
                if (a.id == assessmentId) {
                  return Assessment(
                    id: a.id,
                    classId: a.classId,
                    title: a.title,
                    description: a.description,
                    timeLimitMinutes: a.timeLimitMinutes,
                    openAt: a.openAt,
                    closeAt: a.closeAt,
                    showResultsImmediately: a.showResultsImmediately,
                    resultsReleased: a.resultsReleased,
                    isPublished: false,
                    orderIndex: a.orderIndex,
                    totalPoints: a.totalPoints,
                    questionCount: a.questionCount,
                    submissionCount: a.submissionCount,
                    gradingPeriodNumber: a.gradingPeriodNumber,
                    component: a.component,
                    createdAt: a.createdAt,
                    updatedAt: DateTime.now(),
                    needsSync: true,
                    cachedAt: DateTime.now(),
                  );
                }
                return a;
              }).toList()
            : state.assessments.map((a) => a.id == assessmentId ? assessment : a).toList();
        state = state.copyWith(
          isLoading: false,
          currentAssessment: assessment,
          assessments: updatedList,
          successMessage: 'Assessment moved to draft',
        );
      },
    );
  }

  Future<void> deleteAssessment(String assessmentId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await _deleteAssessment(assessmentId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (_) {
        state = state.copyWith(
          isLoading: false,
          assessments: state.assessments.where((a) => a.id != assessmentId).toList(),
          successMessage: 'Assessment deleted',
          currentAssessment: null,
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
    state = state.copyWith(assessments: orderedAssessments);
    final result = await _reorderAllAssessments(classId: classId, assessmentIds: assessmentIds);
    result.fold(
      (failure) => state = state.copyWith(error: AppErrorMapper.fromFailure(failure)),
      (_) {},
    );
  }

  Future<void> reorderAllQuestions({
    required String assessmentId,
    required List<String> questionIds,
    required List<Question> orderedQuestions,
  }) async {
    state = state.copyWith(questions: orderedQuestions);
    final result = await _reorderAllQuestions(assessmentId: assessmentId, questionIds: questionIds);
    result.fold(
      (failure) => state = state.copyWith(error: AppErrorMapper.fromFailure(failure)),
      (_) {},
    );
  }

  Future<void> addQuestions(AddQuestionsParams params) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await _addQuestions(params);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (questions) => state = state.copyWith(
        isLoading: false,
        questions: [...state.questions, ...questions],
        successMessage: 'Questions added',
      ),
    );
  }

  Future<void> updateAssessment(UpdateAssessmentParams params) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await _updateAssessment(params);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (assessment) {
        state = state.copyWith(
          isLoading: false,
          currentAssessment: assessment,
          successMessage: 'Assessment updated',
        );
        // Sync title/total_points to linked grade item if one exists
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
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await _updateQuestion(params);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (question) => state = state.copyWith(
        isLoading: false,
        successMessage: 'Question updated',
      ),
    );
  }

  Future<void> deleteQuestion(String questionId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await _deleteQuestion(questionId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (_) => state = state.copyWith(
        isLoading: false,
        successMessage: 'Question deleted',
      ),
    );
  }

  Future<void> releaseResults(String assessmentId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await _releaseResults(assessmentId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (assessment) {
        final updatedList = state.assessments.map((a) => a.id == assessmentId ? assessment : a).toList();
        state = state.copyWith(
          isLoading: false,
          currentAssessment: assessment,
          assessments: updatedList,
          successMessage: 'Results released',
        );
      },
    );
  }

  Future<void> loadSubmissions(String assessmentId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getSubmissions(assessmentId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (submissions) => state = state.copyWith(isLoading: false, submissions: submissions),
    );
  }

  Future<void> loadSubmissionDetail(String submissionId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getSubmissionDetail(submissionId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (detail) => state = state.copyWith(isLoading: false, currentSubmission: detail),
    );
  }

  Future<void> overrideAnswer(OverrideAnswerParams params) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await _overrideAnswer(params);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (_) => state = state.copyWith(
        isLoading: false,
        successMessage: 'Grade overridden',
      ),
    );
  }

  Future<void> gradeEssayAnswer(GradeEssayParams params) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await _gradeEssay(params);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (_) => state = state.copyWith(
        isLoading: false,
        successMessage: 'Essay graded',
      ),
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

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }

  @override
  void dispose() {
    _refreshSub.cancel();
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
