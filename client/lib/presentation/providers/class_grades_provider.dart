import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/grading/entities/class_grades.dart';
import 'package:likha/domain/grading/usecases/get_class_grades.dart';
import 'package:likha/injection_container.dart';

class ClassGradesState {
  final ClassGrades? grades;
  final String classId;
  final int termNumber;
  final bool isLoading;
  final String? error;

  const ClassGradesState({
    this.grades,
    this.classId = '',
    this.termNumber = 1,
    this.isLoading = false,
    this.error,
  });

  ClassGradesState copyWith({
    ClassGrades? grades,
    String? classId,
    int? termNumber,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ClassGradesState(
      grades: grades ?? this.grades,
      classId: classId ?? this.classId,
      termNumber: termNumber ?? this.termNumber,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ClassGradesNotifier extends StateNotifier<ClassGradesState> {
  final GetClassGrades _getClassGrades;

  ClassGradesNotifier(this._getClassGrades) : super(const ClassGradesState());

  Future<void> loadClassGrades({
    required String classId,
    required int termNumber,
    bool skipBackgroundRefresh = false,
  }) async {
    final hasCached = state.grades != null &&
        state.classId == classId &&
        state.termNumber == termNumber;
    state = state.copyWith(
      isLoading: !hasCached,
      clearError: true,
      classId: classId,
      termNumber: termNumber,
    );

    final result = await _getClassGrades(
      classId: classId,
      termNumber: termNumber,
      skipBackgroundRefresh: skipBackgroundRefresh,
    );

    if (!mounted) return;

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (grades) => state = state.copyWith(
        isLoading: false,
        grades: grades,
      ),
    );
  }
}

final classGradesProvider = StateNotifierProvider<ClassGradesNotifier, ClassGradesState>(
  (ref) => ClassGradesNotifier(sl<GetClassGrades>()),
);
