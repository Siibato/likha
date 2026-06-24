import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/auth/entities/activity_log.dart';
import 'package:likha/domain/auth/usecases/get_activity_logs.dart';
import 'package:likha/injection_container.dart';

class ActivityLogState {
  final List<ActivityLog> activityLogs;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  ActivityLogState({
    this.activityLogs = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  ActivityLogState copyWith({
    List<ActivityLog>? activityLogs,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ActivityLogState(
      activityLogs: activityLogs ?? this.activityLogs,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ActivityLogNotifier extends StateNotifier<ActivityLogState> {
  final Ref ref;
  final GetActivityLogs _getActivityLogs;

  ActivityLogNotifier(this.ref, this._getActivityLogs)
      : super(ActivityLogState());

  Future<void> loadActivityLogs(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _getActivityLogs(userId);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (logs) => state = state.copyWith(
        isLoading: false,
        activityLogs: logs,
      ),
    );
  }

  void clearActivityLogs() {
    state = state.copyWith(activityLogs: []);
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final activityLogProvider =
    StateNotifierProvider<ActivityLogNotifier, ActivityLogState>((ref) {
  return ActivityLogNotifier(ref, sl<GetActivityLogs>());
});
