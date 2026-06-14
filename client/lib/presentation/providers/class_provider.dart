import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/domain/classes/usecases/add_student.dart';
import 'package:likha/domain/classes/usecases/create_class.dart';
import 'package:likha/domain/classes/usecases/get_all_classes.dart';
import 'package:likha/domain/classes/usecases/get_class_detail.dart';
import 'package:likha/domain/classes/usecases/get_participants.dart';
import 'package:likha/domain/classes/usecases/get_my_classes.dart';
import 'package:likha/domain/classes/usecases/delete_class.dart';
import 'package:likha/domain/classes/usecases/remove_student.dart';
import 'package:likha/domain/classes/usecases/search_students.dart';
import 'package:likha/domain/classes/usecases/update_class.dart';
import 'package:likha/injection_container.dart';

class ClassState {
  final List<ClassEntity> classes;
  final ClassDetail? currentClassDetail;
  final List<User> searchResults;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final Set<String> participantIds; // ids of students enrolled in currentClassDetail
  final Set<String> loadingStudentIds; // ids of students being added/removed

  ClassState({
    this.classes = const [],
    this.currentClassDetail,
    this.searchResults = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.participantIds = const {},
    this.loadingStudentIds = const {},
  });

  ClassState copyWith({
    List<ClassEntity>? classes,
    ClassDetail? currentClassDetail,
    List<User>? searchResults,
    bool? isLoading,
    String? error,
    String? successMessage,
    Set<String>? participantIds,
    Set<String>? loadingStudentIds,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearDetail = false,
    bool clearSearch = false,
    bool clearEnrolled = false,
  }) {
    return ClassState(
      classes: classes ?? this.classes,
      currentClassDetail:
          clearDetail ? null : (currentClassDetail ?? this.currentClassDetail),
      searchResults: clearSearch ? [] : (searchResults ?? this.searchResults),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      participantIds: clearEnrolled ? {} : (participantIds ?? this.participantIds),
      loadingStudentIds: loadingStudentIds ?? this.loadingStudentIds,
    );
  }
}

class ClassNotifier extends StateNotifier<ClassState> {
  final CreateClass _createClass;
  final GetMyClasses _getMyClasses;
  final GetAllClasses _getAllClasses;
  final GetClassDetail _getClassDetail;
  final UpdateClass _updateClass;
  final AddStudent _addStudent;
  final RemoveStudent _removeStudent;
  final SearchStudents _searchStudents;
  final GetParticipants _getParticipants;
  final DeleteClass _deleteClass;

  late StreamSubscription<void> _refreshSub;
  late StreamSubscription<String> _participantsSub;
  bool _isAdminMode = false;

  ClassNotifier(
    this._createClass,
    this._getMyClasses,
    this._getAllClasses,
    this._getClassDetail,
    this._updateClass,
    this._addStudent,
    this._removeStudent,
    this._searchStudents,
    this._getParticipants,
    this._deleteClass,
  ) : super(ClassState()) {
    _refreshSub = sl<DataEventBus>().onClassesChanged.listen((_) {
      if (_isAdminMode) {
        loadAllClasses(skipBackgroundRefresh: true);
      } else {
        loadClasses(skipBackgroundRefresh: true);
      }
    });

    _participantsSub = sl<DataEventBus>().onParticipantsChanged.listen((classId) {
      if (state.currentClassDetail?.id == classId) {
        loadParticipants(classId);
      }
    });
  }

  Future<void> loadClasses({bool skipBackgroundRefresh = false}) async {
    _isAdminMode = false;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _getMyClasses(skipBackgroundRefresh: skipBackgroundRefresh);

    if (!mounted) return;

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (classes) => state = state.copyWith(
        isLoading: false,
        classes: classes,
      ),
    );
  }

  Future<void> loadAllClasses({bool skipBackgroundRefresh = false}) async {
    _isAdminMode = true;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _getAllClasses(skipBackgroundRefresh: skipBackgroundRefresh);

    if (!mounted) return;

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (classes) => state = state.copyWith(
        isLoading: false,
        classes: classes,
      ),
    );
  }

  Future<void> createClass({
    required String title,
    String? description,
    String? teacherId,
    String? teacherUsername,
    String? teacherFullName,
    bool isAdvisory = false,
  }) async {
    state = state.copyWith(clearError: true, clearSuccess: true);

    final result = await _createClass(CreateClassParams(
      title: title,
      description: description,
      teacherId: teacherId,
      teacherUsername: teacherUsername,
      teacherFullName: teacherFullName,
      isAdvisory: isAdvisory,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
      ),
      (mutationResult) => state = state.copyWith(
        classes: [mutationResult.entity, ...state.classes],
        successMessage: 'Class created successfully',
      ),
    );
  }

  Future<void> loadClassDetail(String classId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _getClassDetail(classId);

    // Handle success case
    result.fold(
      (failure) async {},  // Handled below after fold
      (detail) {
        // On success: Derive ids from loaded detail
        final ids = detail.students.map((e) => e.student.id).toSet();
        state = state.copyWith(
          isLoading: false,
          currentClassDetail: detail,
          participantIds: ids,
        );
      },
    );

    // If result is failure, handle offline fallback
    if (result.isLeft()) {
      final failure = result.fold((f) => f, (d) => null);
      if (failure != null) {
        // Type-safe error mapping: NetworkFailure and CacheFailure naturally return null
        state = state.copyWith(
          isLoading: false,
          error: AppErrorMapper.fromFailure(failure),
        );
      }
    }
  }

  Future<void> updateClass({
    required String classId,
    String? title,
    String? description,
    String? teacherId,
    bool? isAdvisory,
  }) async {
    state = state.copyWith(clearError: true, clearSuccess: true);

    final result = await _updateClass(UpdateClassParams(
      classId: classId,
      title: title,
      description: description,
      teacherId: teacherId,
      isAdvisory: isAdvisory,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
      ),
      (_) => state = state.copyWith(
        successMessage: 'Class updated successfully',
      ),
    );
  }

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

  Future<void> searchStudents({String? query}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _searchStudents(query: query);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (students) => state = state.copyWith(
        isLoading: false,
        searchResults: students,
      ),
    );
  }

  Future<void> loadParticipantsOffline(String classId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getParticipants(classId: classId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (students) => state = state.copyWith(isLoading: false, searchResults: students),
    );
  }

  Future<void> loadParticipants(String classId) async {
    final result = await _getParticipants(classId: classId);
    result.fold(
      (failure) {}, // silent: background refresh should not show errors
      (students) {
        final ids = students.map((e) => e.id).toSet();
        state = state.copyWith(
          participantIds: ids,
          searchResults: students,
        );
        // Also update currentClassDetail.students if available
        final currentDetail = state.currentClassDetail;
        if (currentDetail != null) {
          final updatedStudents = students.map((user) {
            return Participant(
              id: 'local_${classId}_${user.id}',
              student: user,
              joinedAt: user.createdAt,
            );
          }).toList();
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

  Future<void> deleteClass(String classId) async {
    state = state.copyWith(clearError: true, clearSuccess: true);

    final result = await _deleteClass(classId: classId);

    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
      ),
      (_) => state = state.copyWith(
        successMessage: 'Class deleted successfully',
      ),
    );
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  void clearSearch() {
    state = state.copyWith(clearSearch: true);
  }

  @override
  void dispose() {
    _refreshSub.cancel();
    _participantsSub.cancel();
    super.dispose();
  }
}

final classProvider = StateNotifierProvider<ClassNotifier, ClassState>((ref) {
  return ClassNotifier(
    sl<CreateClass>(),
    sl<GetMyClasses>(),
    sl<GetAllClasses>(),
    sl<GetClassDetail>(),
    sl<UpdateClass>(),
    sl<AddStudent>(),
    sl<RemoveStudent>(),
    sl<SearchStudents>(),
    sl<GetParticipants>(),
    sl<DeleteClass>(),
  );
});
