import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/logging/sf9_logger.dart';
import 'package:likha/domain/grading/entities/general_average.dart';
import 'package:likha/domain/grading/entities/sf9.dart';
import 'package:likha/domain/grading/usecases/get_general_averages.dart';
import 'package:likha/domain/grading/usecases/get_sf10.dart';
import 'package:likha/domain/grading/usecases/get_sf9.dart';
import 'package:likha/injection_container.dart';

// ===== General Averages (Student List) =====

class GeneralAveragesState {
  final List<StudentGeneralAverage> students;
  final bool isLoading;
  final String? error;

  const GeneralAveragesState({
    this.students = const [],
    this.isLoading = false,
    this.error,
  });

  GeneralAveragesState copyWith({
    List<StudentGeneralAverage>? students,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return GeneralAveragesState(
      students: students ?? this.students,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GeneralAveragesNotifier extends StateNotifier<GeneralAveragesState> {
  final GetGeneralAverages _getGeneralAverages;
  late StreamSubscription<String> _generalAveragesSub;
  String? _currentClassId;
  bool _isLoading = false;

  GeneralAveragesNotifier(this._getGeneralAverages)
      : super(const GeneralAveragesState()) {
    _generalAveragesSub = sl<DataEventBus>().onGeneralAveragesChanged.listen((classId) {
      if (_currentClassId != null && _currentClassId == classId) {
        loadStudents(_currentClassId!, skipBackgroundRefresh: true);
      }
    });
  }

  Future<void> loadStudents(String classId, {bool skipBackgroundRefresh = false}) async {
    if (_isLoading && _currentClassId == classId) return;
    _isLoading = true;
    _currentClassId = classId;
    state = state.copyWith(isLoading: state.students.isEmpty, clearError: true);
    final result = await _getGeneralAverages(classId);
    result.fold(
      (failure) {
        debugPrint(
            'GeneralAverages load failure: ${failure.message} (category: ${failure.category})');
        state = state.copyWith(
          isLoading: false,
          error: AppErrorMapper.fromFailure(failure) ?? failure.message,
        );
      },
      (data) => state = state.copyWith(isLoading: false, students: data.students),
    );
    _isLoading = false;
  }

  void reset() {
    _currentClassId = null;
    state = const GeneralAveragesState();
  }

  @override
  void dispose() {
    _generalAveragesSub.cancel();
    super.dispose();
  }
}

final generalAveragesProvider =
    StateNotifierProvider<GeneralAveragesNotifier, GeneralAveragesState>((ref) {
  return GeneralAveragesNotifier(sl<GetGeneralAverages>());
});

// ===== SF9/SF10 Detail =====

class Sf9DetailState {
  final Sf9Response? currentSf9;
  final bool isLoading;
  final String? error;

  const Sf9DetailState({
    this.currentSf9,
    this.isLoading = false,
    this.error,
  });

  Sf9DetailState copyWith({
    Sf9Response? currentSf9,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearSf9 = false,
  }) {
    return Sf9DetailState(
      currentSf9: clearSf9 ? null : (currentSf9 ?? this.currentSf9),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class Sf9DetailNotifier extends StateNotifier<Sf9DetailState> {
  final GetSf9 _getSf9;
  final GetSf10 _getSf10;
  late StreamSubscription<String> _sf9Sub;
  late StreamSubscription<String> _sf10Sub;
  String? _currentClassId;
  String? _currentStudentId;

  Sf9DetailNotifier(this._getSf9, this._getSf10)
      : super(const Sf9DetailState()) {
    _sf9Sub = sl<DataEventBus>().onSf9Changed.listen((classId) {
      if (_currentClassId != null && _currentClassId == classId && _currentStudentId != null) {
        loadSf9(_currentClassId!, _currentStudentId!, skipBackgroundRefresh: true);
      }
    });
    _sf10Sub = sl<DataEventBus>().onSf10Changed.listen((classId) {
      if (_currentClassId != null && _currentClassId == classId && _currentStudentId != null) {
        loadSf10(_currentClassId!, _currentStudentId!, skipBackgroundRefresh: true);
      }
    });
  }

  Future<void> loadSf9(String classId, String studentId, {bool skipBackgroundRefresh = false}) async {
    final log = Sf9Logger.instance;
    final hasCached = state.currentSf9 != null && _currentClassId == classId && _currentStudentId == studentId;
    log.log('loadSf9: classId=$classId studentId=$studentId hasCached=$hasCached skipBackgroundRefresh=$skipBackgroundRefresh');
    _currentClassId = classId;
    _currentStudentId = studentId;
    state = state.copyWith(isLoading: !hasCached, clearError: true);
    final result = await _getSf9(GetSf9Params(classId: classId, studentId: studentId, skipBackgroundRefresh: skipBackgroundRefresh));
    // Ignore stale results if user navigated to a different student
    if (_currentClassId != classId || _currentStudentId != studentId) {
      log.log('loadSf9: ignoring stale result (user navigated away)');
      return;
    }
    result.fold(
      (failure) {
        log.warn('loadSf9: result is Left (failure) => ${failure.message}');
        state = state.copyWith(
          isLoading: false,
          error: AppErrorMapper.fromFailure(failure) ?? failure.message,
        );
      },
      (sf9) {
        log.log('loadSf9: result is Right (success) => studentName=${sf9.studentName} subjects=${sf9.subjects.length}');
        state = state.copyWith(isLoading: false, currentSf9: sf9);
      },
    );
  }

  Future<void> loadSf10(String classId, String studentId, {bool skipBackgroundRefresh = false}) async {
    final hasCached = state.currentSf9 != null && _currentClassId == classId && _currentStudentId == studentId;
    _currentClassId = classId;
    _currentStudentId = studentId;
    state = state.copyWith(isLoading: !hasCached, clearError: true);
    final result = await _getSf10(GetSf10Params(classId: classId, studentId: studentId, skipBackgroundRefresh: skipBackgroundRefresh));
    // Ignore stale results if user navigated to a different student
    if (_currentClassId != classId || _currentStudentId != studentId) return;
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure) ?? failure.message,
      ),
      (sf10) => state = state.copyWith(isLoading: false, currentSf9: sf10),
    );
  }

  void reset() {
    _currentClassId = null;
    _currentStudentId = null;
    state = const Sf9DetailState();
  }

  @override
  void dispose() {
    _sf9Sub.cancel();
    _sf10Sub.cancel();
    super.dispose();
  }
}

final sf9DetailProvider =
    StateNotifierProvider<Sf9DetailNotifier, Sf9DetailState>((ref) {
  return Sf9DetailNotifier(sl<GetSf9>(), sl<GetSf10>());
});
