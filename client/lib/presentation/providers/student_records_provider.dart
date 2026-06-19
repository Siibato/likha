import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/domain/student_records/entities/learner_details.dart';
import 'package:likha/domain/student_records/entities/attendance_record.dart';
import 'package:likha/domain/student_records/entities/core_values_record.dart';
import 'package:likha/domain/student_records/entities/sf10_response.dart';
import 'package:likha/domain/student_records/usecases/get_learner_details.dart';
import 'package:likha/domain/student_records/usecases/upsert_learner_details.dart';
import 'package:likha/domain/student_records/usecases/get_attendance.dart';
import 'package:likha/domain/student_records/usecases/upsert_attendance.dart';
import 'package:likha/domain/student_records/usecases/get_core_values.dart';
import 'package:likha/domain/student_records/usecases/upsert_core_values.dart';
import 'package:likha/domain/student_records/usecases/get_sf10_v2.dart';
import 'package:likha/injection_container.dart';

// ===== Learner Details =====

class LearnerDetailsState {
  final LearnerDetails? details;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const LearnerDetailsState({this.details, this.isLoading = false, this.isSaving = false, this.error});

  LearnerDetailsState copyWith({LearnerDetails? details, bool? isLoading, bool? isSaving, String? error, bool clearError = false, bool clearDetails = false}) {
    return LearnerDetailsState(
      details: clearDetails ? null : (details ?? this.details),
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LearnerDetailsNotifier extends StateNotifier<LearnerDetailsState> {
  final GetLearnerDetails _get;
  final UpsertLearnerDetails _upsert;

  LearnerDetailsNotifier(this._get, this._upsert) : super(const LearnerDetailsState());

  Future<void> load(String classId, String studentId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearDetails: true);
    final result = await _get(GetLearnerDetailsParams(classId: classId, studentId: studentId));
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(f) ?? f.message),
      (d) => state = state.copyWith(isLoading: false, details: d),
    );
  }

  Future<bool> save(String classId, String studentId, Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, clearError: true);
    final result = await _upsert(UpsertLearnerDetailsParams(classId: classId, studentId: studentId, data: data));
    bool success = false;
    result.fold(
      (f) => state = state.copyWith(isSaving: false, error: AppErrorMapper.fromFailure(f) ?? f.message),
      (d) {
        state = state.copyWith(isSaving: false, details: d);
        success = true;
      },
    );
    return success;
  }

  void reset() => state = const LearnerDetailsState();
}

final learnerDetailsProvider = StateNotifierProvider<LearnerDetailsNotifier, LearnerDetailsState>((ref) {
  return LearnerDetailsNotifier(sl<GetLearnerDetails>(), sl<UpsertLearnerDetails>());
});

// ===== Attendance =====

class AttendanceState {
  final List<AttendanceRecord> records;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const AttendanceState({this.records = const [], this.isLoading = false, this.isSaving = false, this.error});

  AttendanceState copyWith({List<AttendanceRecord>? records, bool? isLoading, bool? isSaving, String? error, bool clearError = false}) {
    return AttendanceState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final GetAttendance _get;
  final UpsertAttendance _upsert;

  AttendanceNotifier(this._get, this._upsert) : super(const AttendanceState());

  Future<void> load(String classId, String studentId, {String? schoolYear}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _get(GetAttendanceParams(classId: classId, studentId: studentId, schoolYear: schoolYear));
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

  void reset() => state = const AttendanceState();
}

final attendanceProvider = StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  return AttendanceNotifier(sl<GetAttendance>(), sl<UpsertAttendance>());
});

// ===== Core Values =====

class CoreValuesState {
  final List<CoreValuesRecord> records;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const CoreValuesState({this.records = const [], this.isLoading = false, this.isSaving = false, this.error});

  CoreValuesState copyWith({List<CoreValuesRecord>? records, bool? isLoading, bool? isSaving, String? error, bool clearError = false}) {
    return CoreValuesState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CoreValuesNotifier extends StateNotifier<CoreValuesState> {
  final GetCoreValues _get;
  final UpsertCoreValues _upsert;

  CoreValuesNotifier(this._get, this._upsert) : super(const CoreValuesState());

  Future<void> load(String classId, String studentId, {String? schoolYear}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _get(GetCoreValuesParams(classId: classId, studentId: studentId, schoolYear: schoolYear));
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
              r.coreValue != record.coreValue ||
              r.behaviorStatement != record.behaviorStatement ||
              r.gradingPeriodNumber != record.gradingPeriodNumber),
          record,
        ];
        state = state.copyWith(isSaving: false, records: updated);
        success = true;
      },
    );
    return success;
  }

  void reset() => state = const CoreValuesState();
}

final coreValuesProvider = StateNotifierProvider<CoreValuesNotifier, CoreValuesState>((ref) {
  return CoreValuesNotifier(sl<GetCoreValues>(), sl<UpsertCoreValues>());
});

// ===== SF10 =====

class Sf10State {
  final Sf10Response? data;
  final bool isLoading;
  final String? error;

  const Sf10State({this.data, this.isLoading = false, this.error});

  Sf10State copyWith({Sf10Response? data, bool? isLoading, String? error, bool clearError = false, bool clearData = false}) {
    return Sf10State(
      data: clearData ? null : (data ?? this.data),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class Sf10Notifier extends StateNotifier<Sf10State> {
  final GetSf10V2 _get;
  late StreamSubscription<String> _sub;
  String? _classId;
  String? _studentId;

  Sf10Notifier(this._get) : super(const Sf10State()) {
    _sub = sl<DataEventBus>().onSf10Changed.listen((classId) {
      if (_classId == classId && _studentId != null) {
        load(_classId!, _studentId!);
      }
    });
  }

  Future<void> load(String classId, String studentId) async {
    _classId = classId;
    _studentId = studentId;
    state = state.copyWith(isLoading: true, clearError: true, clearData: true);
    final result = await _get(GetSf10V2Params(classId: classId, studentId: studentId));
    if (_classId != classId || _studentId != studentId) return;
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(f) ?? f.message),
      (d) => state = state.copyWith(isLoading: false, data: d),
    );
  }

  void reset() {
    _classId = null;
    _studentId = null;
    state = const Sf10State();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final sf10Provider = StateNotifierProvider<Sf10Notifier, Sf10State>((ref) {
  return Sf10Notifier(sl<GetSf10V2>());
});
