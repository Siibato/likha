import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/usecases/get_assignment_detail.dart';
import 'package:likha/injection_container.dart';

class AssignmentDetailState {
  final Assignment? currentAssignment;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  AssignmentDetailState({
    this.currentAssignment,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  AssignmentDetailState copyWith({
    Assignment? currentAssignment,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearAssignment = false,
  }) {
    return AssignmentDetailState(
      currentAssignment: clearAssignment
          ? null
          : (currentAssignment ?? this.currentAssignment),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class AssignmentDetailNotifier extends StateNotifier<AssignmentDetailState> {
  final Ref ref;
  final GetAssignmentDetail _getAssignmentDetail;

  AssignmentDetailNotifier(this.ref, this._getAssignmentDetail)
      : super(AssignmentDetailState());

  Future<void> loadAssignmentDetail(String assignmentId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getAssignmentDetail(assignmentId);
    result.fold(
      (failure) => state = state.copyWith(
          isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (assignment) => state = state.copyWith(
        isLoading: false,
        currentAssignment: assignment,
      ),
    );
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  void clearCurrentAssignment() {
    state = state.copyWith(clearAssignment: true);
  }

  String? get currentError => state.error;

  AssignmentDetailState get currentState => state;
}

final assignmentDetailProvider =
    StateNotifierProvider<AssignmentDetailNotifier, AssignmentDetailState>((ref) {
  return AssignmentDetailNotifier(ref, sl<GetAssignmentDetail>());
});
