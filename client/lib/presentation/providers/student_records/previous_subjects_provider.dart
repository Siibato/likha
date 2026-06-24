import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/student_records/entities/previous_subject.dart';
import 'package:likha/domain/student_records/usecases/get_previous_subjects.dart';
import 'package:likha/domain/student_records/usecases/upsert_previous_subject.dart';
import 'package:likha/injection_container.dart';

class PreviousSubjectsState {
  final List<PreviousSubject> records;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const PreviousSubjectsState({this.records = const [], this.isLoading = false, this.isSaving = false, this.error});

  PreviousSubjectsState copyWith({List<PreviousSubject>? records, bool? isLoading, bool? isSaving, String? error, bool clearError = false}) {
    return PreviousSubjectsState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PreviousSubjectsNotifier extends StateNotifier<PreviousSubjectsState> {
  final GetPreviousSubjects _get;
  final UpsertPreviousSubject _upsert;
  String? _classId;
  String? _studentId;

  PreviousSubjectsNotifier(this._get, this._upsert) : super(const PreviousSubjectsState());

  Future<void> load(String classId, String studentId, {required String schoolHistoryId}) async {
    _classId = classId;
    _studentId = studentId;
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _get(GetPreviousSubjectsParams(classId: classId, studentId: studentId, schoolHistoryId: schoolHistoryId));
    if (_classId != classId || _studentId != studentId) return;
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(f) ?? f.message),
      (r) => state = state.copyWith(isLoading: false, records: r),
    );
  }

  Future<bool> save(String classId, String studentId, Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, clearError: true);
    final result = await _upsert(UpsertPreviousSubjectParams(classId: classId, studentId: studentId, data: data));
    bool success = false;
    result.fold(
      (f) => state = state.copyWith(isSaving: false, error: AppErrorMapper.fromFailure(f) ?? f.message),
      (record) {
        final updated = [
          ...state.records.where((r) => r.subjectName != record.subjectName),
          record,
        ];
        state = state.copyWith(isSaving: false, records: updated);
        success = true;
      },
    );
    return success;
  }

  void reset() {
    _classId = null;
    _studentId = null;
    state = const PreviousSubjectsState();
  }
}

final previousSubjectsProvider = StateNotifierProvider<PreviousSubjectsNotifier, PreviousSubjectsState>((ref) {
  return PreviousSubjectsNotifier(sl<GetPreviousSubjects>(), sl<UpsertPreviousSubject>());
});
