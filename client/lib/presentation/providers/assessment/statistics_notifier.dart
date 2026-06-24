import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';
import 'package:likha/domain/assessments/usecases/get_statistics.dart';
import 'package:likha/injection_container.dart';

const _unset = Object();

class StatisticsState {
  final AssessmentStatistics? statistics;
  final bool isLoading;
  final String? error;

  StatisticsState({
    this.statistics,
    this.isLoading = false,
    this.error,
  });

  StatisticsState copyWith({
    Object? statistics = _unset,
    bool? isLoading,
    Object? error = _unset,
  }) {
    return StatisticsState(
      statistics: identical(statistics, _unset) ? this.statistics : statistics as AssessmentStatistics?,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

class StatisticsNotifier extends StateNotifier<StatisticsState> {
  final GetStatistics _getStatistics;

  StatisticsNotifier(this._getStatistics) : super(StatisticsState());

  Future<void> loadStatistics(String assessmentId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getStatistics(assessmentId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (stats) => state = state.copyWith(isLoading: false, statistics: stats),
    );
  }

  String? get currentError => state.error;

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final statisticsProvider = StateNotifierProvider<StatisticsNotifier, StatisticsState>((ref) {
  return StatisticsNotifier(sl<GetStatistics>());
});
