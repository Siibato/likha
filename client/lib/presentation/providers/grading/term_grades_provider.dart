import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/grading/entities/term_grade.dart';
import 'package:likha/domain/grading/usecases/compute_grades.dart';
import 'package:likha/domain/grading/usecases/get_grade_summary.dart';
import 'package:likha/domain/grading/usecases/get_term_grades.dart';
import 'package:likha/domain/grading/usecases/update_term_grade.dart';
import 'package:likha/injection_container.dart';

const _unset = Object();

class TermGradesState {
  final List<TermGrade> grades;
  final List<Map<String, dynamic>>? summary;
  final bool isLoading;
  final String? error;

  TermGradesState({
    this.grades = const [],
    this.summary,
    this.isLoading = false,
    this.error,
  });

  TermGradesState copyWith({
    List<TermGrade>? grades,
    Object? summary = _unset,
    bool? isLoading,
    Object? error = _unset,
  }) {
    return TermGradesState(
      grades: grades ?? this.grades,
      summary: identical(summary, _unset) ? this.summary : summary as List<Map<String, dynamic>>?,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

class TermGradesNotifier extends StateNotifier<TermGradesState> {
  final GetTermGrades _getTermGrades;
  final ComputeGrades _computeGrades;
  final GetGradeSummary _getGradeSummary;
  final UpdateTermGrade _updateTermGrade;

  TermGradesNotifier(
    this._getTermGrades,
    this._computeGrades,
    this._getGradeSummary,
    this._updateTermGrade,
  ) : super(TermGradesState());

  Future<void> loadGrades(String classId, int term) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getTermGrades(
      classId: classId,
      termNumber: term,
    );
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (grades) => state = state.copyWith(isLoading: false, grades: grades),
    );
  }

  Future<void> computeGrades(String classId, int term) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _computeGrades(classId: classId, termNumber: term);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (_) => state = state.copyWith(isLoading: false),
    );
  }

  Future<void> loadSummary(String classId, int term) async {
    state = state.copyWith(isLoading: state.summary == null || state.summary!.isEmpty, error: null);
    final result = await _getGradeSummary(classId: classId, termNumber: term);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (summary) => state = state.copyWith(isLoading: false, summary: summary),
    );
  }

  Future<void> updateTermGrade({
    required String classId,
    required String studentId,
    required int term,
    required int transmutedGrade,
  }) async {
    state = state.copyWith(error: null);
    final result = await _updateTermGrade(
      classId: classId,
      studentId: studentId,
      termNumber: term,
      transmutedGrade: transmutedGrade,
    );
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
      ),
      (_) {},
    );
  }
}

final termGradesProvider = StateNotifierProvider<TermGradesNotifier, TermGradesState>((ref) {
  return TermGradesNotifier(
    sl<GetTermGrades>(),
    sl<ComputeGrades>(),
    sl<GetGradeSummary>(),
    sl<UpdateTermGrade>(),
  );
});
