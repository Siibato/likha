import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/classes/usecases/add_student.dart';
import 'package:likha/domain/classes/usecases/remove_student.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/providers/class/class_detail_provider.dart';
import 'package:likha/presentation/providers/class/class_list_provider.dart';

class EnrollmentState {
  final Set<String> loadingStudentIds;
  final String? error;
  final String? successMessage;

  EnrollmentState({
    this.loadingStudentIds = const {},
    this.error,
    this.successMessage,
  });

  EnrollmentState copyWith({
    Set<String>? loadingStudentIds,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return EnrollmentState(
      loadingStudentIds: loadingStudentIds ?? this.loadingStudentIds,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class EnrollmentNotifier extends StateNotifier<EnrollmentState> {
  final AddStudent _addStudent;
  final RemoveStudent _removeStudent;
  final ClassDetailNotifier _classDetailNotifier;
  final ClassListNotifier _classListNotifier;

  EnrollmentNotifier(
    this._addStudent,
    this._removeStudent,
    this._classDetailNotifier,
    this._classListNotifier,
  ) : super(EnrollmentState());

  Future<void> addStudent({
    required String classId,
    required String studentId,
  }) async {
    state = state.copyWith(
      clearError: true,
      clearSuccess: true,
      loadingStudentIds: {...state.loadingStudentIds, studentId},
    );

    final result = await _addStudent(AddStudentParams(
      classId: classId,
      studentId: studentId,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
        loadingStudentIds: Set<String>.from(state.loadingStudentIds)..remove(studentId),
      ),
      (mutationResult) {
        _classDetailNotifier.optimisticAddStudent(mutationResult.entity);
        _classListNotifier.optimisticUpdateStudentCount(classId, 1);
        state = state.copyWith(
          successMessage: 'Student added to class',
          loadingStudentIds: Set<String>.from(state.loadingStudentIds)..remove(studentId),
        );
      },
    );
  }

  Future<void> removeStudent({
    required String classId,
    required String studentId,
  }) async {
    state = state.copyWith(
      clearError: true,
      clearSuccess: true,
      loadingStudentIds: {...state.loadingStudentIds, studentId},
    );

    final result = await _removeStudent(RemoveStudentParams(
      classId: classId,
      studentId: studentId,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
        loadingStudentIds: Set<String>.from(state.loadingStudentIds)..remove(studentId),
      ),
      (_) {
        _classDetailNotifier.optimisticRemoveStudent(studentId);
        _classListNotifier.optimisticUpdateStudentCount(classId, -1);
        state = state.copyWith(
          successMessage: 'Student removed from class',
          loadingStudentIds: Set<String>.from(state.loadingStudentIds)..remove(studentId),
        );
      },
    );
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final enrollmentProvider = StateNotifierProvider<EnrollmentNotifier, EnrollmentState>((ref) {
  return EnrollmentNotifier(
    sl<AddStudent>(),
    sl<RemoveStudent>(),
    ref.read(classDetailProvider.notifier),
    ref.read(classListProvider.notifier),
  );
});
