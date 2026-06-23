import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/student_records/entities/previous_attendance.dart';
import 'package:likha/domain/student_records/usecases/get_previous_attendance.dart';
import 'package:likha/domain/student_records/usecases/upsert_previous_attendance.dart';
import 'package:likha/injection_container.dart';

class PreviousAttendanceState {
  final List<PreviousAttendance> records;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const PreviousAttendanceState({this.records = const [], this.isLoading = false, this.isSaving = false, this.error});

  PreviousAttendanceState copyWith({List<PreviousAttendance>? records, bool? isLoading, bool? isSaving, String? error, bool clearError = false}) {
    return PreviousAttendanceState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PreviousAttendanceNotifier extends StateNotifier<PreviousAttendanceState> {
  final GetPreviousAttendance _get;
  final UpsertPreviousAttendance _upsert;
  String? _classId;
  String? _studentId;

  PreviousAttendanceNotifier(this._get, this._upsert) : super(const PreviousAttendanceState());

  Future<void> load(String classId, String studentId, {required String schoolHistoryId}) async {
    _classId = classId;
    _studentId = studentId;
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _get(GetPreviousAttendanceParams(classId: classId, studentId: studentId, schoolHistoryId: schoolHistoryId));
    if (_classId != classId || _studentId != studentId) return;
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(f) ?? f.message),
      (r) => state = state.copyWith(isLoading: false, records: r),
    );
  }

  Future<bool> save(String classId, String studentId, Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, clearError: true);
    final result = await _upsert(UpsertPreviousAttendanceParams(classId: classId, studentId: studentId, data: data));
    bool success = false;
    result.fold(
      (f) => state = state.copyWith(isSaving: false, error: AppErrorMapper.fromFailure(f) ?? f.message),
      (record) {
        final updated = [
          ...state.records.where((r) => r.month != record.month),
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
    state = const PreviousAttendanceState();
  }
}

final previousAttendanceProvider = StateNotifierProvider<PreviousAttendanceNotifier, PreviousAttendanceState>((ref) {
  return PreviousAttendanceNotifier(sl<GetPreviousAttendance>(), sl<UpsertPreviousAttendance>());
});
