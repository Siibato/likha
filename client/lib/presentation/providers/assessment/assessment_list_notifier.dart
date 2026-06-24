import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/usecases/create_assessment.dart';
import 'package:likha/domain/assessments/usecases/delete_assessment.dart';
import 'package:likha/domain/assessments/usecases/get_assessments.dart';
import 'package:likha/domain/assessments/usecases/publish_assessment.dart';
import 'package:likha/domain/assessments/usecases/reorder_assessment.dart';
import 'package:likha/domain/assessments/usecases/unpublish_assessment.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';
import 'package:likha/injection_container.dart';
import 'assessment_utils.dart';

const _unset = Object();

class AssessmentListState {
  final List<Assessment> assessments;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  AssessmentListState({
    this.assessments = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  AssessmentListState copyWith({
    List<Assessment>? assessments,
    bool? isLoading,
    Object? error = _unset,
    Object? successMessage = _unset,
  }) {
    return AssessmentListState(
      assessments: assessments ?? this.assessments,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      successMessage: identical(successMessage, _unset) ? this.successMessage : successMessage as String?,
    );
  }
}

class AssessmentListNotifier extends StateNotifier<AssessmentListState> {
  final CreateAssessment _createAssessment;
  final GetAssessments _getAssessments;
  final PublishAssessment _publishAssessment;
  final UnpublishAssessment _unpublishAssessment;
  final DeleteAssessment _deleteAssessment;
  final ReorderAllAssessments _reorderAllAssessments;

  String? _currentClassId;

  AssessmentListNotifier(
    this._createAssessment,
    this._getAssessments,
    this._publishAssessment,
    this._unpublishAssessment,
    this._deleteAssessment,
    this._reorderAllAssessments,
  ) : super(AssessmentListState());

  Future<void> loadAssessments(String classId, {bool publishedOnly = false, bool skipBackgroundRefresh = false}) async {
    if (_currentClassId != classId) {
      _currentClassId = classId;
      state = state.copyWith(isLoading: true, error: null, assessments: []);
    } else {
      state = state.copyWith(isLoading: state.assessments.isEmpty, error: null);
    }
    final result = await _getAssessments(classId, publishedOnly: publishedOnly, skipBackgroundRefresh: skipBackgroundRefresh);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (assessments) => state = state.copyWith(isLoading: false, assessments: assessments),
    );
  }

  Future<Assessment?> createAssessment(CreateAssessmentParams params) async {
    final previousAssessments = state.assessments;
    state = state.copyWith(error: null, successMessage: null);
    final result = await _createAssessment(params);
    return result.fold<Assessment?>(
      (failure) {
        state = state.copyWith(
          error: AppErrorMapper.fromFailure(failure),
          assessments: previousAssessments,
        );
        return null;
      },
      (mutationResult) {
        final assessment = mutationResult.entity;
        state = state.copyWith(
          assessments: [assessment, ...state.assessments],
          successMessage: 'Assessment created',
        );
        if (assessment.component != null && assessment.termNumber != null) {
          sl<GradingRepository>().createGradeItem(
            classId: params.classId,
            data: {
              'title': assessment.title,
              'component': toGradeComponent(assessment.component!),
              'term_number': assessment.termNumber!,
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

  Future<void> publishAssessment(String assessmentId) async {
    final previousAssessments = state.assessments;
    final existing = state.assessments.where((a) => a.id == assessmentId).firstOrNull;
    if (existing != null) {
      final optimistic = withUpdatedAssessment(existing, isPublished: true);
      state = state.copyWith(
        error: null,
        successMessage: null,
        assessments: state.assessments.map((a) => a.id == assessmentId ? optimistic : a).toList(),
      );
    } else {
      state = state.copyWith(error: null, successMessage: null);
    }

    final result = await _publishAssessment(assessmentId);
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
        assessments: previousAssessments,
      ),
      (mutationResult) {
        final assessment = mutationResult.entity;
        final updatedList = assessment.classId.isEmpty
            ? state.assessments
                .map((a) => a.id == assessmentId ? withUpdatedAssessment(a, isPublished: true) : a)
                .toList()
            : state.assessments.map((a) => a.id == assessmentId ? assessment : a).toList();
        state = state.copyWith(assessments: updatedList, successMessage: 'Assessment published');
      },
    );
  }

  Future<void> unpublishAssessment(String assessmentId) async {
    final previousAssessments = state.assessments;
    final existing = state.assessments.where((a) => a.id == assessmentId).firstOrNull;
    if (existing != null) {
      final optimistic = withUpdatedAssessment(existing, isPublished: false);
      state = state.copyWith(
        error: null,
        successMessage: null,
        assessments: state.assessments.map((a) => a.id == assessmentId ? optimistic : a).toList(),
      );
    } else {
      state = state.copyWith(error: null, successMessage: null);
    }

    final result = await _unpublishAssessment(assessmentId);
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
        assessments: previousAssessments,
      ),
      (mutationResult) {
        final assessment = mutationResult.entity;
        final updatedList = assessment.classId.isEmpty
            ? state.assessments
                .map((a) => a.id == assessmentId ? withUpdatedAssessment(a, isPublished: false) : a)
                .toList()
            : state.assessments.map((a) => a.id == assessmentId ? assessment : a).toList();
        state = state.copyWith(assessments: updatedList, successMessage: 'Assessment moved to draft');
      },
    );
  }

  Future<void> deleteAssessment(String assessmentId) async {
    final previousAssessments = state.assessments;
    state = state.copyWith(
      error: null,
      successMessage: null,
      assessments: state.assessments.where((a) => a.id != assessmentId).toList(),
    );
    final result = await _deleteAssessment(assessmentId);
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
        assessments: previousAssessments,
      ),
      (_) {
        state = state.copyWith(successMessage: 'Assessment deleted');
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

  String? get currentError => state.error;

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

final assessmentListProvider = StateNotifierProvider<AssessmentListNotifier, AssessmentListState>((ref) {
  return AssessmentListNotifier(
    sl<CreateAssessment>(),
    sl<GetAssessments>(),
    sl<PublishAssessment>(),
    sl<UnpublishAssessment>(),
    sl<DeleteAssessment>(),
    sl<ReorderAllAssessments>(),
  );
});
