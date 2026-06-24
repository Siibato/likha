import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/student_records/entities/school_history.dart';
import 'package:likha/domain/student_records/usecases/get_school_history.dart';
import 'package:likha/domain/student_records/usecases/create_school_history.dart';
import 'package:likha/domain/student_records/usecases/update_school_history.dart';
import 'package:likha/domain/student_records/usecases/delete_school_history.dart';
import 'package:likha/injection_container.dart';

class SchoolHistoryState {
  final List<SchoolHistory> records;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const SchoolHistoryState({this.records = const [], this.isLoading = false, this.isSaving = false, this.error});

  SchoolHistoryState copyWith({List<SchoolHistory>? records, bool? isLoading, bool? isSaving, String? error, bool clearError = false}) {
    return SchoolHistoryState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SchoolHistoryNotifier extends StateNotifier<SchoolHistoryState> {
  final GetSchoolHistory _get;
  final CreateSchoolHistory _create;
  final UpdateSchoolHistory _update;
  final DeleteSchoolHistory _delete;
  String? _classId;
  String? _studentId;

  SchoolHistoryNotifier(this._get, this._create, this._update, this._delete) : super(const SchoolHistoryState());

  Future<void> load(String classId, String studentId) async {
    _classId = classId;
    _studentId = studentId;
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _get(GetSchoolHistoryParams(classId: classId, studentId: studentId));
    if (_classId != classId || _studentId != studentId) return;
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(f) ?? f.message),
      (r) => state = state.copyWith(isLoading: false, records: r),
    );
  }

  Future<bool> create(String classId, String studentId, Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, clearError: true);
    final result = await _create(CreateSchoolHistoryParams(classId: classId, studentId: studentId, data: data));
    bool success = false;
    result.fold(
      (f) => state = state.copyWith(isSaving: false, error: AppErrorMapper.fromFailure(f) ?? f.message),
      (record) {
        state = state.copyWith(isSaving: false, records: [...state.records, record]);
        success = true;
      },
    );
    return success;
  }

  Future<bool> update(String classId, String studentId, String historyId, Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, clearError: true);
    final result = await _update(UpdateSchoolHistoryParams(classId: classId, studentId: studentId, historyId: historyId, data: data));
    bool success = false;
    result.fold(
      (f) => state = state.copyWith(isSaving: false, error: AppErrorMapper.fromFailure(f) ?? f.message),
      (record) {
        final updated = state.records.map((r) => r.id == historyId ? record : r).toList();
        state = state.copyWith(isSaving: false, records: updated);
        success = true;
      },
    );
    return success;
  }

  Future<bool> delete(String classId, String studentId, String historyId) async {
    state = state.copyWith(isSaving: true, clearError: true);
    final result = await _delete(DeleteSchoolHistoryParams(classId: classId, studentId: studentId, historyId: historyId));
    bool success = false;
    result.fold(
      (f) => state = state.copyWith(isSaving: false, error: AppErrorMapper.fromFailure(f) ?? f.message),
      (_) {
        final updated = state.records.where((r) => r.id != historyId).toList();
        state = state.copyWith(isSaving: false, records: updated);
        success = true;
      },
    );
    return success;
  }

  void reset() {
    _classId = null;
    _studentId = null;
    state = const SchoolHistoryState();
  }
}

final schoolHistoryProvider = StateNotifierProvider<SchoolHistoryNotifier, SchoolHistoryState>((ref) {
  return SchoolHistoryNotifier(
    sl<GetSchoolHistory>(),
    sl<CreateSchoolHistory>(),
    sl<UpdateSchoolHistory>(),
    sl<DeleteSchoolHistory>(),
  );
});
