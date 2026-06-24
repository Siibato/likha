import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/domain/classes/usecases/create_class.dart';
import 'package:likha/domain/classes/usecases/get_all_classes.dart';
import 'package:likha/domain/classes/usecases/get_my_classes.dart';
import 'package:likha/domain/classes/usecases/delete_class.dart';
import 'package:likha/domain/classes/usecases/update_class.dart';
import 'package:likha/injection_container.dart';

class ClassListState {
  final List<ClassEntity> classes;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  ClassListState({
    this.classes = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  ClassListState copyWith({
    List<ClassEntity>? classes,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ClassListState(
      classes: classes ?? this.classes,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ClassListNotifier extends StateNotifier<ClassListState> {
  final CreateClass _createClass;
  final GetMyClasses _getMyClasses;
  final GetAllClasses _getAllClasses;
  final UpdateClass _updateClass;
  final DeleteClass _deleteClass;

  ClassListNotifier(
    this._createClass,
    this._getMyClasses,
    this._getAllClasses,
    this._updateClass,
    this._deleteClass,
  ) : super(ClassListState());

  Future<void> loadClasses({bool skipBackgroundRefresh = false}) async {
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

  void optimisticUpdateStudentCount(String classId, int delta) {
    final updated = state.classes.map((c) {
      if (c.id == classId) {
        return ClassEntity(
          id: c.id,
          title: c.title,
          description: c.description,
          teacherId: c.teacherId,
          teacherUsername: c.teacherUsername,
          teacherFullName: c.teacherFullName,
          isArchived: c.isArchived,
          isAdvisory: c.isAdvisory,
          studentCount: (c.studentCount + delta).clamp(0, 999999),
          termType: c.termType,
          createdAt: c.createdAt,
          updatedAt: c.updatedAt,
          cachedAt: c.cachedAt,
          syncStatus: c.syncStatus,
        );
      }
      return c;
    }).toList();

    state = state.copyWith(classes: updated);
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final classListProvider = StateNotifierProvider<ClassListNotifier, ClassListState>((ref) {
  return ClassListNotifier(
    sl<CreateClass>(),
    sl<GetMyClasses>(),
    sl<GetAllClasses>(),
    sl<UpdateClass>(),
    sl<DeleteClass>(),
  );
});
