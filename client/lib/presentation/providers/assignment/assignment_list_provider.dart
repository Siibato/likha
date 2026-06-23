import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/usecases/create_assignment.dart';
import 'package:likha/domain/assignments/usecases/delete_assignment.dart';
import 'package:likha/domain/assignments/usecases/get_assignments.dart';
import 'package:likha/domain/assignments/usecases/publish_assignment.dart';
import 'package:likha/domain/assignments/usecases/reorder_assignment.dart';
import 'package:likha/domain/assignments/usecases/unpublish_assignment.dart';
import 'package:likha/domain/assignments/usecases/update_assignment.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';
import 'package:likha/injection_container.dart';

class AssignmentListState {
  final List<Assignment> assignments;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  AssignmentListState({
    this.assignments = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  AssignmentListState copyWith({
    List<Assignment>? assignments,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AssignmentListState(
      assignments: assignments ?? this.assignments,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class AssignmentListNotifier extends StateNotifier<AssignmentListState> {
  final Ref ref;
  final CreateAssignment _createAssignment;
  final GetAssignments _getAssignments;
  final UpdateAssignment _updateAssignment;
  final DeleteAssignment _deleteAssignment;
  final PublishAssignment _publishAssignment;
  final UnpublishAssignment _unpublishAssignment;
  final ReorderAllAssignments _reorderAllAssignments;

  String? _currentClassId;

  AssignmentListNotifier(
    this.ref,
    this._createAssignment,
    this._getAssignments,
    this._updateAssignment,
    this._deleteAssignment,
    this._publishAssignment,
    this._unpublishAssignment,
    this._reorderAllAssignments,
  ) : super(AssignmentListState());

  Future<void> loadAssignments(String classId,
      {bool publishedOnly = false, bool skipBackgroundRefresh = false}) async {
    if (_currentClassId != classId) {
      _currentClassId = classId;
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        assignments: [],
      );
    } else {
      state = state.copyWith(
          isLoading: state.assignments.isEmpty, clearError: true);
    }
    final result = await _getAssignments(classId,
        publishedOnly: publishedOnly, skipBackgroundRefresh: skipBackgroundRefresh);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (assignments) =>
          state = state.copyWith(isLoading: false, assignments: assignments),
    );
  }

  String _toGradeComponent(String c) {
    switch (c) {
      case 'written_work':
        return 'ww';
      case 'performance_task':
        return 'pt';
      case 'term_assessment':
        return 'qa';
      default:
        return c;
    }
  }

  Future<void> createAssignment(CreateAssignmentParams params) async {
    state = state.copyWith(clearError: true, clearSuccess: true);

    final result = await _createAssignment(params);
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
      ),
      (mutationResult) {
        final assignment = mutationResult.entity;
        state = state.copyWith(successMessage: 'Assignment created');
        if (assignment.component != null && assignment.termNumber != null) {
          sl<GradingRepository>().createGradeItem(
            classId: params.classId,
            data: {
              'title': assignment.title,
              'component': _toGradeComponent(assignment.component!),
              'term_number': assignment.termNumber!,
              'total_points': assignment.totalPoints.toDouble(),
              'is_departmental_exam': false,
              'source_type': 'assignment',
              'source_id': assignment.id,
              'order_index': 0,
            },
          );
        }
        ref.invalidate(assignmentListProvider);
      },
    );
  }

  Future<void> updateAssignment(UpdateAssignmentParams params) async {
    state = state.copyWith(clearError: true, clearSuccess: true);
    final result = await _updateAssignment(params);
    result.fold(
      (failure) =>
          state = state.copyWith(error: AppErrorMapper.fromFailure(failure)),
      (mutationResult) {
        state = state.copyWith(successMessage: 'Assignment updated');
        sl<GradingRepository>().findGradeItemBySourceId(params.assignmentId).then((res) {
          res.fold((_) {}, (item) {
            if (item != null) {
              final updates = <String, dynamic>{};
              if (params.title != null) updates['title'] = params.title;
              if (params.totalPoints != null) {
                updates['total_points'] = params.totalPoints!.toDouble();
              }
              if (updates.isNotEmpty) {
                sl<GradingRepository>().updateGradeItem(id: item.id, data: updates);
              }
            }
          });
        });
        ref.invalidate(assignmentListProvider);
      },
    );
  }

  Future<void> publishAssignment(String assignmentId) async {
    state = state.copyWith(clearError: true, clearSuccess: true);
    final result = await _publishAssignment(assignmentId);
    result.fold(
      (failure) =>
          state = state.copyWith(error: AppErrorMapper.fromFailure(failure)),
      (mutationResult) {
        state = state.copyWith(successMessage: 'Assignment published');
        ref.invalidate(assignmentListProvider);
      },
    );
  }

  Future<void> unpublishAssignment(String assignmentId) async {
    state = state.copyWith(clearError: true, clearSuccess: true);
    final result = await _unpublishAssignment(assignmentId);
    result.fold(
      (failure) =>
          state = state.copyWith(error: AppErrorMapper.fromFailure(failure)),
      (mutationResult) {
        state = state.copyWith(successMessage: 'Assignment moved to draft');
        ref.invalidate(assignmentListProvider);
      },
    );
  }

  Future<void> deleteAssignment(String assignmentId) async {
    state = state.copyWith(clearError: true, clearSuccess: true);
    final result = await _deleteAssignment(assignmentId);
    result.fold(
      (failure) =>
          state = state.copyWith(error: AppErrorMapper.fromFailure(failure)),
      (_) {
        state = state.copyWith(successMessage: 'Assignment deleted');
        sl<GradingRepository>().findGradeItemBySourceId(assignmentId).then((res) {
          res.fold((_) {}, (item) {
            if (item != null) {
              sl<GradingRepository>().deleteGradeItem(id: item.id);
            }
          });
        });
        ref.invalidate(assignmentListProvider);
      },
    );
  }

  Future<void> reorderAllAssignments({
    required String classId,
    required List<String> assignmentIds,
    required List<Assignment> orderedAssignments,
  }) async {
    state = state.copyWith(clearError: true);
    final result = await _reorderAllAssignments(
      classId: classId,
      assignmentIds: assignmentIds,
    );
    result.fold(
      (failure) =>
          state = state.copyWith(error: AppErrorMapper.fromFailure(failure)),
      (mutationResult) {
        state = state.copyWith(successMessage: 'Assignments reordered');
        ref.invalidate(assignmentListProvider);
      },
    );
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  String? get currentError => state.error;
}

final assignmentListProvider =
    StateNotifierProvider<AssignmentListNotifier, AssignmentListState>((ref) {
  return AssignmentListNotifier(
    ref,
    sl<CreateAssignment>(),
    sl<GetAssignments>(),
    sl<UpdateAssignment>(),
    sl<DeleteAssignment>(),
    sl<PublishAssignment>(),
    sl<UnpublishAssignment>(),
    sl<ReorderAllAssignments>(),
  );
});
