import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/student_records/entities/core_values_record.dart';
import 'package:likha/domain/student_records/usecases/get_core_values.dart';
import 'package:likha/domain/student_records/usecases/upsert_core_values.dart';
import 'package:likha/injection_container.dart';

class CoreValuesState {
  final List<CoreValuesRecord> records;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const CoreValuesState({this.records = const [], this.isLoading = false, this.isSaving = false, this.error});

  CoreValuesState copyWith({List<CoreValuesRecord>? records, bool? isLoading, bool? isSaving, String? error, bool clearError = false, bool clearRecords = false}) {
    return CoreValuesState(
      records: clearRecords ? const [] : (records ?? this.records),
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CoreValuesNotifier extends StateNotifier<CoreValuesState> {
  final GetCoreValues _get;
  final UpsertCoreValues _upsert;
  String? _classId;
  String? _studentId;

  CoreValuesNotifier(this._get, this._upsert) : super(const CoreValuesState());

  Future<void> load(String classId, String studentId, {String? schoolYear}) async {
    final hasCached = state.records.isNotEmpty && _classId == classId && _studentId == studentId;
    _classId = classId;
    _studentId = studentId;
    state = state.copyWith(isLoading: !hasCached, clearError: true, clearRecords: !hasCached);
    final result = await _get(GetCoreValuesParams(classId: classId, studentId: studentId, schoolYear: schoolYear));
    if (_classId != classId || _studentId != studentId) return;
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(f) ?? f.message),
      (r) => state = state.copyWith(isLoading: false, records: r),
    );
  }

  Future<bool> save(String classId, String studentId, Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, clearError: true);
    final result = await _upsert(UpsertCoreValuesParams(classId: classId, studentId: studentId, data: data));
    bool success = false;
    result.fold(
      (f) => state = state.copyWith(isSaving: false, error: AppErrorMapper.fromFailure(f) ?? f.message),
      (record) {
        final updated = [
          ...state.records.where((r) =>
              r.coreValueId != record.coreValueId ||
              r.termNumber != record.termNumber),
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
    state = const CoreValuesState();
  }
}

final coreValuesProvider = StateNotifierProvider<CoreValuesNotifier, CoreValuesState>((ref) {
  return CoreValuesNotifier(sl<GetCoreValues>(), sl<UpsertCoreValues>());
});
