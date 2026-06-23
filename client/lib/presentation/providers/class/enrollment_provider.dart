import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/classes/usecases/add_student.dart';
import 'package:likha/domain/classes/usecases/get_participants.dart';
import 'package:likha/domain/classes/usecases/remove_student.dart';
import 'package:likha/injection_container.dart';

class EnrollmentState {
  final Set<String> loadingStudentIds;
  final List<User> participants;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  EnrollmentState({
    this.loadingStudentIds = const {},
    this.participants = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  EnrollmentState copyWith({
    Set<String>? loadingStudentIds,
    List<User>? participants,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearParticipants = false,
  }) {
    return EnrollmentState(
      loadingStudentIds: loadingStudentIds ?? this.loadingStudentIds,
      participants: clearParticipants ? const [] : (participants ?? this.participants),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class EnrollmentNotifier extends StateNotifier<EnrollmentState> {
  final AddStudent _addStudent;
  final RemoveStudent _removeStudent;
  final GetParticipants _getParticipants;

  EnrollmentNotifier(
    this._addStudent,
    this._removeStudent,
    this._getParticipants,
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
      (_) => state = state.copyWith(
        successMessage: 'Student added to class',
        loadingStudentIds: Set<String>.from(state.loadingStudentIds)..remove(studentId),
      ),
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
      (_) => state = state.copyWith(
        successMessage: 'Student removed from class',
        loadingStudentIds: Set<String>.from(state.loadingStudentIds)..remove(studentId),
      ),
    );
  }

  Future<void> loadParticipants(String classId) async {
    final result = await _getParticipants(classId: classId);
    result.fold(
      (failure) => state = state.copyWith(error: AppErrorMapper.fromFailure(failure)),
      (students) => state = state.copyWith(participants: students),
    );
  }

  Future<void> loadParticipantsOffline(String classId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getParticipants(classId: classId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (students) => state = state.copyWith(isLoading: false, participants: students),
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
    sl<GetParticipants>(),
  );
});
