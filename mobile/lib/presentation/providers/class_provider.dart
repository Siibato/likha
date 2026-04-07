import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/data/models/auth/user_model.dart';
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
  }

  Future<void> loadClasses({bool skipBackgroundRefresh = false}) async {
    _isAdminMode = false;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _getMyClasses(skipBackgroundRefresh: skipBackgroundRefresh);

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
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

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
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (newClass) => state = state.copyWith(
        isLoading: false,
        classes: [newClass, ...state.classes],
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
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final result = await _updateClass(UpdateClassParams(
      classId: classId,
      title: title,
      description: description,
      teacherId: teacherId,
      isAdvisory: isAdvisory,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (updatedClass) {
        // Update the class in the classes list
        final updatedClasses = state.classes.map((c) {
          if (c.id == classId) {
            return updatedClass;
          }
          return c;
        }).toList();

        state = state.copyWith(
          isLoading: false,
          classes: updatedClasses,
          successMessage: 'Class updated successfully',
        );
        // Reload class detail to get updated info
        loadClassDetail(classId);
      },
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

    // Try to get the student from search results to show in UI immediately
    final studentToAdd = state.searchResults.firstWhere(
      (u) => u.id == studentId,
      orElse: () => UserModel(
        id: studentId,
        username: '',
        fullName: '',
        role: 'student',
        accountStatus: 'pending',
        isActive: false,
        createdAt: DateTime.now(),
      ),
    );

    final currentDetail = state.currentClassDetail;

    // Optimistic update: immediately show student as added
    if (currentDetail != null) {
      final optimisticParticipant = Participant(
        id: 'temp_${studentToAdd.id}', // Temporary ID that will be updated on sync
        student: studentToAdd,
        joinedAt: DateTime.now(),
      );

      final updatedDetail = ClassDetail(
        id: currentDetail.id,
        title: currentDetail.title,
        description: currentDetail.description,
        teacherId: currentDetail.teacherId,
        isArchived: currentDetail.isArchived,
        isAdvisory: currentDetail.isAdvisory,
        students: [optimisticParticipant, ...currentDetail.students],
        createdAt: currentDetail.createdAt,
        updatedAt: currentDetail.updatedAt,
      );

      state = state.copyWith(
        currentClassDetail: updatedDetail,
        participantIds: {...state.participantIds, studentId},
      );
    }

    // Perform the actual operation in background
    final result = await _addStudent(AddStudentParams(
      classId: classId,
      studentId: studentId,
    ));

    result.fold(
      (failure) {
        // On failure, remove the optimistically added student and show error
        if (currentDetail != null) {
          final revertedDetail = ClassDetail(
            id: currentDetail.id,
            title: currentDetail.title,
            description: currentDetail.description,
            teacherId: currentDetail.teacherId,
            isArchived: currentDetail.isArchived,
            isAdvisory: currentDetail.isAdvisory,
            students: currentDetail.students, // Revert to original students
            createdAt: currentDetail.createdAt,
            updatedAt: currentDetail.updatedAt,
          );
          state = state.copyWith(
            currentClassDetail: revertedDetail,
            participantIds: Set<String>.from(state.participantIds)..remove(studentId),
            error: AppErrorMapper.fromFailure(failure),
            loadingStudentIds: Set<String>.from(state.loadingStudentIds)..remove(studentId),
          );
        } else {
          state = state.copyWith(
            error: AppErrorMapper.fromFailure(failure),
            loadingStudentIds: state.loadingStudentIds..remove(studentId),
          );
        }
      },
      (participant) {
        // On success, update with real participant data from server
        if (currentDetail != null) {
          final updatedDetail = ClassDetail(
            id: currentDetail.id,
            title: currentDetail.title,
            description: currentDetail.description,
            teacherId: currentDetail.teacherId,
            isArchived: currentDetail.isArchived,
            isAdvisory: currentDetail.isAdvisory,
            students: currentDetail.students.map((s) {
              // Replace temp participant with real one
              if (s.id.startsWith('temp_') && s.student.id == studentId) {
                return participant;
              }
              return s;
            }).toList(),
            createdAt: currentDetail.createdAt,
            updatedAt: currentDetail.updatedAt,
          );
          state = state.copyWith(
            currentClassDetail: updatedDetail,
            successMessage: 'Student added to class',
            loadingStudentIds: Set<String>.from(state.loadingStudentIds)..remove(studentId),
          );
        } else {
          state = state.copyWith(
            successMessage: 'Student added to class',
            loadingStudentIds: Set<String>.from(state.loadingStudentIds)..remove(studentId),
          );
        }
        // Reload class detail in background to sync with server
        loadClassDetail(classId);
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

    final currentDetail = state.currentClassDetail;
    final removedStudent = currentDetail?.students
        .cast<Participant?>()
        .firstWhere((e) => e?.student.id == studentId, orElse: () => null);

    // Optimistic update: immediately remove the student
    if (currentDetail != null) {
      final updatedDetail = ClassDetail(
        id: currentDetail.id,
        title: currentDetail.title,
        description: currentDetail.description,
        teacherId: currentDetail.teacherId,
        isArchived: currentDetail.isArchived,
        isAdvisory: currentDetail.isAdvisory,
        students: currentDetail.students
            .where((e) => e.student.id != studentId)
            .toList(),
        createdAt: currentDetail.createdAt,
        updatedAt: currentDetail.updatedAt,
      );
      state = state.copyWith(
        currentClassDetail: updatedDetail,
        participantIds: Set<String>.from(state.participantIds)..remove(studentId),
      );
    }

    // Perform the actual operation in background
    final result = await _removeStudent(RemoveStudentParams(
      classId: classId,
      studentId: studentId,
    ));

    result.fold(
      (failure) {
        // On failure, restore the removed student and show error
        if (currentDetail != null && removedStudent != null) {
          state = state.copyWith(
            currentClassDetail: currentDetail, // Restore original detail
            participantIds: Set<String>.from(state.participantIds)..add(studentId),
            error: AppErrorMapper.fromFailure(failure),
            loadingStudentIds: Set<String>.from(state.loadingStudentIds)..remove(studentId),
          );
        } else {
          state = state.copyWith(
            error: AppErrorMapper.fromFailure(failure),
            loadingStudentIds: Set<String>.from(state.loadingStudentIds)..remove(studentId),
          );
        }
      },
      (_) {
        // On success, confirm the removal
        state = state.copyWith(
          successMessage: 'Student removed from class',
          loadingStudentIds: Set<String>.from(state.loadingStudentIds)..remove(studentId),
        );
        // Reload class detail in background to sync with server
        loadClassDetail(classId);
      },
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

  Future<void> deleteClass(String classId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _deleteClass(classId: classId);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (_) => state = state.copyWith(
        isLoading: false,
        classes: state.classes.where((c) => c.id != classId).toList(),
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
