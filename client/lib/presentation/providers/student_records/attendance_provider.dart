import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/student_records/entities/attendance_record.dart';
import 'package:likha/domain/student_records/usecases/get_attendance.dart';
import 'package:likha/domain/student_records/usecases/upsert_attendance.dart';
import 'package:likha/injection_container.dart';

class AttendanceState {
  final List<AttendanceRecord> records;
  final bool isLoading;
  final bool isSaving;
  final bool isBulkSaving;
  final String? error;

  const AttendanceState({this.records = const [], this.isLoading = false, this.isSaving = false, this.isBulkSaving = false, this.error});

  AttendanceState copyWith({List<AttendanceRecord>? records, bool? isLoading, bool? isSaving, bool? isBulkSaving, String? error, bool clearError = false, bool clearRecords = false}) {
    return AttendanceState(
      records: clearRecords ? const [] : (records ?? this.records),
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isBulkSaving: isBulkSaving ?? this.isBulkSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final GetAttendance _get;
  final UpsertAttendance _upsert;
  String? _classId;
  String? _studentId;

  AttendanceNotifier(this._get, this._upsert) : super(const AttendanceState());

  Future<void> load(String classId, String studentId, {String? schoolYear}) async {
    final hasCached = state.records.isNotEmpty && _classId == classId && _studentId == studentId;
    _classId = classId;
    _studentId = studentId;
    state = state.copyWith(isLoading: !hasCached, clearError: true, clearRecords: !hasCached);
    final result = await _get(GetAttendanceParams(classId: classId, studentId: studentId, schoolYear: schoolYear));
    if (_classId != classId || _studentId != studentId) return;
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(f) ?? f.message),
      (r) => state = state.copyWith(isLoading: false, records: r),
    );
  }

  Future<bool> save(String classId, String studentId, Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, clearError: true);
    final result = await _upsert(UpsertAttendanceParams(classId: classId, studentId: studentId, data: data));
    bool success = false;
    result.fold(
      (f) => state = state.copyWith(isSaving: false, error: AppErrorMapper.fromFailure(f) ?? f.message),
      (record) {
        final updated = [...state.records.where((r) => r.month != record.month || r.schoolYear != record.schoolYear), record];
        state = state.copyWith(isSaving: false, records: updated);
        success = true;
      },
    );
    return success;
  }

  Future<(bool, int, int)> bulkSaveSchoolDays({
    required String classId,
    required List<String> studentIds,
    required String schoolYear,
    required String month,
    required int schoolDays,
  }) async {
    state = state.copyWith(isBulkSaving: true, clearError: true);
    int successCount = 0;
    int failCount = 0;

    for (final studentId in studentIds) {
      final getResult = await _get(GetAttendanceParams(classId: classId, studentId: studentId, schoolYear: schoolYear));
      int daysPresent = 0;
      getResult.fold(
        (_) {},
        (records) {
          final existing = records.where((r) => r.month == month).firstOrNull;
          daysPresent = existing?.daysPresent ?? 0;
          if (daysPresent > schoolDays) daysPresent = schoolDays;
        },
      );

      final saveResult = await _upsert(UpsertAttendanceParams(
        classId: classId,
        studentId: studentId,
        data: {
          'class_id': classId,
          'school_year': schoolYear,
          'month': month,
          'school_days': schoolDays,
          'days_present': daysPresent,
        },
      ));
      saveResult.fold(
        (_) => failCount++,
        (_) {
          successCount++;
        },
      );
    }

    state = state.copyWith(isBulkSaving: false);
    return (failCount == 0, successCount, failCount);
  }

  void reset() {
    _classId = null;
    _studentId = null;
    state = const AttendanceState();
  }
}

final attendanceProvider = StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  return AttendanceNotifier(sl<GetAttendance>(), sl<UpsertAttendance>());
});
