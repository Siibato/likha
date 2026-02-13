import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/domain/classes/usecases/add_student.dart';
import 'package:likha/domain/classes/usecases/create_class.dart';
import 'package:likha/domain/classes/usecases/get_class_detail.dart';
import 'package:likha/domain/classes/usecases/get_my_classes.dart';
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

  ClassState({
    this.classes = const [],
    this.currentClassDetail,
    this.searchResults = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  ClassState copyWith({
    List<ClassEntity>? classes,
    ClassDetail? currentClassDetail,
    List<User>? searchResults,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearDetail = false,
    bool clearSearch = false,
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
    );
  }
}

class ClassNotifier extends StateNotifier<ClassState> {
  final CreateClass _createClass;
  final GetMyClasses _getMyClasses;
  final GetClassDetail _getClassDetail;
  final UpdateClass _updateClass;
  final AddStudent _addStudent;
  final RemoveStudent _removeStudent;
  final SearchStudents _searchStudents;

  ClassNotifier(
    this._createClass,
    this._getMyClasses,
    this._getClassDetail,
    this._updateClass,
    this._addStudent,
    this._removeStudent,
    this._searchStudents,
  ) : super(ClassState());

  Future<void> loadClasses() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _getMyClasses();

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
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
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final result = await _createClass(CreateClassParams(
      title: title,
      description: description,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (newClass) {
        state = state.copyWith(
          isLoading: false,
          classes: [newClass, ...state.classes],
          successMessage: 'Class created successfully',
        );
      },
    );
  }

  Future<void> loadClassDetail(String classId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _getClassDetail(classId);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (detail) => state = state.copyWith(
        isLoading: false,
        currentClassDetail: detail,
      ),
    );
  }

  Future<void> updateClass({
    required String classId,
    String? title,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final result = await _updateClass(UpdateClassParams(
      classId: classId,
      title: title,
      description: description,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
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
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final result = await _addStudent(AddStudentParams(
      classId: classId,
      studentId: studentId,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (enrollment) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Student added to class',
        );
        // Reload class detail to get updated student list
        loadClassDetail(classId);
      },
    );
  }

  Future<void> removeStudent({
    required String classId,
    required String studentId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final result = await _removeStudent(RemoveStudentParams(
      classId: classId,
      studentId: studentId,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (_) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Student removed from class',
        );
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
        error: failure.message,
      ),
      (students) => state = state.copyWith(
        isLoading: false,
        searchResults: students,
      ),
    );
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  void clearSearch() {
    state = state.copyWith(clearSearch: true);
  }
}

final classProvider = StateNotifierProvider<ClassNotifier, ClassState>((ref) {
  return ClassNotifier(
    sl<CreateClass>(),
    sl<GetMyClasses>(),
    sl<GetClassDetail>(),
    sl<UpdateClass>(),
    sl<AddStudent>(),
    sl<RemoveStudent>(),
    sl<SearchStudents>(),
  );
});
