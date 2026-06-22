import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/domain/student_records/entities/learner_details.dart';
import 'package:likha/domain/student_records/entities/attendance_record.dart';
import 'package:likha/domain/student_records/entities/core_values_record.dart';
import 'package:likha/domain/student_records/entities/school_history.dart';
import 'package:likha/domain/student_records/entities/previous_subject.dart';
import 'package:likha/domain/student_records/entities/previous_attendance.dart';
import 'package:likha/domain/student_records/entities/sf10_response.dart';
import 'package:likha/domain/student_records/usecases/get_learner_details.dart';
import 'package:likha/domain/student_records/usecases/upsert_learner_details.dart';
import 'package:likha/domain/student_records/usecases/get_attendance.dart';
import 'package:likha/domain/student_records/usecases/upsert_attendance.dart';
import 'package:likha/domain/student_records/usecases/get_core_values.dart';
import 'package:likha/domain/student_records/usecases/upsert_core_values.dart';
import 'package:likha/domain/student_records/usecases/get_sf10_v2.dart';
import 'package:likha/domain/student_records/usecases/get_school_history.dart';
import 'package:likha/domain/student_records/usecases/create_school_history.dart';
import 'package:likha/domain/student_records/usecases/update_school_history.dart';
import 'package:likha/domain/student_records/usecases/delete_school_history.dart';
import 'package:likha/domain/student_records/usecases/get_previous_subjects.dart';
import 'package:likha/domain/student_records/usecases/upsert_previous_subject.dart';
import 'package:likha/domain/student_records/usecases/get_previous_attendance.dart';
import 'package:likha/domain/student_records/usecases/upsert_previous_attendance.dart';
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
  late StreamSubscription<String> _sub;
  String? _classId;
  String? _studentId;

  LearnerDetailsNotifier(this._get, this._upsert) : super(const LearnerDetailsState()) {
    _sub = sl<DataEventBus>().onLearnerDetailsChanged.listen((studentId) {
      if (_studentId == studentId && _classId != null) {
        load(_classId!, _studentId!);
      }
    });
  }

  Future<void> load(String classId, String studentId) async {
    final hasCached = state.details != null && _classId == classId && _studentId == studentId;
    _classId = classId;
    _studentId = studentId;
    state = state.copyWith(isLoading: !hasCached, clearError: true, clearDetails: !hasCached);
    final result = await _get(GetLearnerDetailsParams(classId: classId, studentId: studentId));
    if (_classId != classId || _studentId != studentId) return;
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

  void reset() {
    _classId = null;
    _studentId = null;
    state = const LearnerDetailsState();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final learnerDetailsProvider = StateNotifierProvider<LearnerDetailsNotifier, LearnerDetailsState>((ref) {
  return LearnerDetailsNotifier(sl<GetLearnerDetails>(), sl<UpsertLearnerDetails>());
});

// ===== Attendance =====

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
  late StreamSubscription<String> _sub;
  String? _classId;
  String? _studentId;

  AttendanceNotifier(this._get, this._upsert) : super(const AttendanceState()) {
    _sub = sl<DataEventBus>().onAttendanceChanged.listen((studentId) {
      if (_studentId == studentId && _classId != null) {
        load(_classId!, _studentId!);
      }
    });
  }

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
        sl<DataEventBus>().notifyAttendanceChanged(studentId);
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
          sl<DataEventBus>().notifyAttendanceChanged(studentId);
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

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
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
  late StreamSubscription<String> _sub;
  String? _classId;
  String? _studentId;

  CoreValuesNotifier(this._get, this._upsert) : super(const CoreValuesState()) {
    _sub = sl<DataEventBus>().onCoreValuesChanged.listen((studentId) {
      if (_studentId == studentId && _classId != null) {
        load(_classId!, _studentId!);
      }
    });
  }

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
        sl<DataEventBus>().notifyCoreValuesChanged(studentId);
      },
    );
    return success;
  }

  void reset() {
    _classId = null;
    _studentId = null;
    state = const CoreValuesState();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
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
    final hasCached = state.data != null && _classId == classId && _studentId == studentId;
    _classId = classId;
    _studentId = studentId;
    state = state.copyWith(isLoading: !hasCached, clearError: true);
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

// ===== School History =====

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
  late StreamSubscription<String> _sub;
  String? _classId;
  String? _studentId;

  SchoolHistoryNotifier(this._get, this._create, this._update, this._delete) : super(const SchoolHistoryState()) {
    _sub = sl<DataEventBus>().onSchoolHistoryChanged.listen((studentId) {
      if (_studentId == studentId && _classId != null) {
        load(_classId!, _studentId!);
      }
    });
  }

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

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
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

// ===== Previous Subjects =====

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
  late StreamSubscription<String> _sub;
  String? _classId;
  String? _studentId;
  String? _schoolHistoryId;

  PreviousSubjectsNotifier(this._get, this._upsert) : super(const PreviousSubjectsState()) {
    _sub = sl<DataEventBus>().onPreviousSubjectsChanged.listen((historyId) {
      if (_schoolHistoryId == historyId && _classId != null && _studentId != null) {
        load(_classId!, _studentId!, schoolHistoryId: _schoolHistoryId!);
      }
    });
  }

  Future<void> load(String classId, String studentId, {required String schoolHistoryId}) async {
    _classId = classId;
    _studentId = studentId;
    _schoolHistoryId = schoolHistoryId;
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
    _schoolHistoryId = null;
    state = const PreviousSubjectsState();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final previousSubjectsProvider = StateNotifierProvider<PreviousSubjectsNotifier, PreviousSubjectsState>((ref) {
  return PreviousSubjectsNotifier(sl<GetPreviousSubjects>(), sl<UpsertPreviousSubject>());
});

// ===== Previous Attendance =====

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
  late StreamSubscription<String> _sub;
  String? _classId;
  String? _studentId;
  String? _schoolHistoryId;

  PreviousAttendanceNotifier(this._get, this._upsert) : super(const PreviousAttendanceState()) {
    _sub = sl<DataEventBus>().onPreviousAttendanceChanged.listen((historyId) {
      if (_schoolHistoryId == historyId && _classId != null && _studentId != null) {
        load(_classId!, _studentId!, schoolHistoryId: _schoolHistoryId!);
      }
    });
  }

  Future<void> load(String classId, String studentId, {required String schoolHistoryId}) async {
    _classId = classId;
    _studentId = studentId;
    _schoolHistoryId = schoolHistoryId;
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
    _schoolHistoryId = null;
    state = const PreviousAttendanceState();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final previousAttendanceProvider = StateNotifierProvider<PreviousAttendanceNotifier, PreviousAttendanceState>((ref) {
  return PreviousAttendanceNotifier(sl<GetPreviousAttendance>(), sl<UpsertPreviousAttendance>());
});
