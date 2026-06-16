import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/domain/grading/entities/class_grades.dart';
import 'package:likha/domain/grading/usecases/get_class_grades.dart';
import 'package:likha/injection_container.dart';

class ClassGradesState {
  final ClassGrades? grades;
  final String classId;
  final int gradingPeriodNumber;
  final bool isLoading;
  final String? error;

  const ClassGradesState({
    this.grades,
    this.classId = '',
    this.gradingPeriodNumber = 1,
    this.isLoading = false,
    this.error,
  });

  ClassGradesState copyWith({
    ClassGrades? grades,
    String? classId,
    int? gradingPeriodNumber,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ClassGradesState(
      grades: grades ?? this.grades,
      classId: classId ?? this.classId,
      gradingPeriodNumber: gradingPeriodNumber ?? this.gradingPeriodNumber,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ClassGradesNotifier extends StateNotifier<ClassGradesState> {
  final GetClassGrades _getClassGrades;

  late StreamSubscription<String> _gradesSub;

  ClassGradesNotifier(this._getClassGrades) : super(const ClassGradesState()) {
    _gradesSub = sl<DataEventBus>().onGradesChanged.listen((classId) {
      if (state.classId == classId && state.grades != null) {
        loadClassGrades(
          classId: classId,
          gradingPeriodNumber: state.gradingPeriodNumber,
          skipBackgroundRefresh: true,
        );
      }
    });
  }

  Future<void> loadClassGrades({
    required String classId,
    required int gradingPeriodNumber,
    bool skipBackgroundRefresh = false,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      classId: classId,
      gradingPeriodNumber: gradingPeriodNumber,
    );

    final result = await _getClassGrades(
      classId: classId,
      gradingPeriodNumber: gradingPeriodNumber,
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

  @override
  void dispose() {
    _gradesSub.cancel();
    super.dispose();
  }
}

final classGradesProvider = StateNotifierProvider<ClassGradesNotifier, ClassGradesState>(
  (ref) => ClassGradesNotifier(sl<GetClassGrades>()),
);
