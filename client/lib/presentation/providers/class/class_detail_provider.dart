import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/classes/usecases/get_class_detail.dart';
import 'package:likha/domain/classes/usecases/get_participants.dart';
import 'package:likha/injection_container.dart';

class ClassDetailState {
  final ClassDetail? currentClassDetail;
  final Set<String> participantIds;
  final List<User> participants;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  ClassDetailState({
    this.currentClassDetail,
    this.participantIds = const {},
    this.participants = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  ClassDetailState copyWith({
    ClassDetail? currentClassDetail,
    Set<String>? participantIds,
    List<User>? participants,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearDetail = false,
    bool clearParticipants = false,
  }) {
    return ClassDetailState(
      currentClassDetail: clearDetail ? null : (currentClassDetail ?? this.currentClassDetail),
      participantIds: participantIds ?? this.participantIds,
      participants: clearParticipants ? const [] : (participants ?? this.participants),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ClassDetailNotifier extends StateNotifier<ClassDetailState> {
  final GetClassDetail _getClassDetail;
  final GetParticipants _getParticipants;

  ClassDetailNotifier(
    this._getClassDetail,
    this._getParticipants,
  ) : super(ClassDetailState());

  Future<void> loadClassDetail(String classId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearDetail: true, clearParticipants: true);

    final result = await _getClassDetail(classId);

    result.fold(
      (failure) async {},
      (detail) {
        final ids = detail.students.map((e) => e.student.id).toSet();
        state = state.copyWith(
          isLoading: false,
          currentClassDetail: detail,
          participantIds: ids,
        );
      },
    );

    if (result.isLeft()) {
      final failure = result.fold((f) => f, (d) => null);
      if (failure != null) {
        state = state.copyWith(
          isLoading: false,
          error: AppErrorMapper.fromFailure(failure),
        );
      }
    }
  }

  Future<void> refreshClassDetail(String classId) async {
    final result = await _getClassDetail(classId);
    result.fold(
      (failure) {},
      (detail) {
        final ids = detail.students.map((e) => e.student.id).toSet();
        state = state.copyWith(
          currentClassDetail: detail,
          participantIds: ids,
        );
      },
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

  Future<void> loadParticipants(String classId) async {
    final result = await _getParticipants(classId: classId);
    result.fold(
      (failure) {},
      (students) {
        final ids = students.map((e) => e.id).toSet();
        state = state.copyWith(
          participantIds: ids,
          participants: students,
        );
        final currentDetail = state.currentClassDetail;
        if (currentDetail != null) {
          final updatedStudents = students.map((user) {
            return Participant(
              id: 'local_${classId}_${user.id}',
              student: user,
              joinedAt: user.createdAt,
            );
          }).toList()
            ..sort((a, b) {
              final lastCmp = a.student.lastName.toLowerCase().compareTo(
                  b.student.lastName.toLowerCase());
              if (lastCmp != 0) return lastCmp;
              return a.student.firstName.toLowerCase().compareTo(
                  b.student.firstName.toLowerCase());
            });
          state = state.copyWith(
            currentClassDetail: ClassDetail(
              id: currentDetail.id,
              title: currentDetail.title,
              description: currentDetail.description,
              teacherId: currentDetail.teacherId,
              isArchived: currentDetail.isArchived,
              isAdvisory: currentDetail.isAdvisory,
              students: updatedStudents,
              createdAt: currentDetail.createdAt,
              updatedAt: currentDetail.updatedAt,
            ),
          );
        }
      },
    );
  }

  void optimisticAddStudent(Participant participant) {
    final currentDetail = state.currentClassDetail;
    if (currentDetail == null) return;

    final updatedStudents = [...currentDetail.students, participant]
      ..sort((a, b) {
        final lastCmp = a.student.lastName.toLowerCase().compareTo(
            b.student.lastName.toLowerCase());
        if (lastCmp != 0) return lastCmp;
        return a.student.firstName.toLowerCase().compareTo(
            b.student.firstName.toLowerCase());
      });

    state = state.copyWith(
      currentClassDetail: _cloneDetailWithStudents(currentDetail, updatedStudents),
      participantIds: {...state.participantIds, participant.student.id},
    );
  }

  void optimisticRemoveStudent(String studentId) {
    final currentDetail = state.currentClassDetail;
    if (currentDetail == null) return;

    final updatedStudents = currentDetail.students
        .where((p) => p.student.id != studentId)
        .toList();

    final updatedIds = state.participantIds..remove(studentId);

    state = state.copyWith(
      currentClassDetail: _cloneDetailWithStudents(currentDetail, updatedStudents),
      participantIds: updatedIds,
    );
  }

  ClassDetail _cloneDetailWithStudents(ClassDetail detail, List<Participant> students) {
    return ClassDetail(
      id: detail.id,
      title: detail.title,
      description: detail.description,
      teacherId: detail.teacherId,
      isArchived: detail.isArchived,
      isAdvisory: detail.isAdvisory,
      gradeLevel: detail.gradeLevel,
      schoolYear: detail.schoolYear,
      students: students,
      createdAt: detail.createdAt,
      updatedAt: detail.updatedAt,
    );
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final classDetailProvider = StateNotifierProvider<ClassDetailNotifier, ClassDetailState>((ref) {
  return ClassDetailNotifier(
    sl<GetClassDetail>(),
    sl<GetParticipants>(),
  );
});
