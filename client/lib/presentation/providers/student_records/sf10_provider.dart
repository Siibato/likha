import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/student_records/entities/sf10_response.dart';
import 'package:likha/domain/student_records/usecases/get_sf10_v2.dart';
import 'package:likha/injection_container.dart';

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
  String? _classId;
  String? _studentId;

  Sf10Notifier(this._get) : super(const Sf10State());

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
}

final sf10Provider = StateNotifierProvider<Sf10Notifier, Sf10State>((ref) {
  return Sf10Notifier(sl<GetSf10V2>());
});
