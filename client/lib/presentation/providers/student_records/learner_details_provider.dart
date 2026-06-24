import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/student_records/entities/learner_details.dart';
import 'package:likha/domain/student_records/usecases/get_learner_details.dart';
import 'package:likha/domain/student_records/usecases/upsert_learner_details.dart';
import 'package:likha/injection_container.dart';

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
  String? _classId;
  String? _studentId;

  LearnerDetailsNotifier(this._get, this._upsert) : super(const LearnerDetailsState());

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
}

final learnerDetailsProvider = StateNotifierProvider<LearnerDetailsNotifier, LearnerDetailsState>((ref) {
  return LearnerDetailsNotifier(sl<GetLearnerDetails>(), sl<UpsertLearnerDetails>());
});
