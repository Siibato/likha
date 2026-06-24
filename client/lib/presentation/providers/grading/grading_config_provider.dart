import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/logging/provider_logger.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/usecases/get_grading_config.dart';
import 'package:likha/domain/grading/usecases/setup_grading.dart';
import 'package:likha/domain/grading/usecases/update_grading_config.dart';
import 'package:likha/injection_container.dart';

const _unset = Object();

class GradingConfigState {
  final List<GradeConfig> configs;
  final bool isConfigured;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  GradingConfigState({
    this.configs = const [],
    this.isConfigured = false,
    this.isLoading = true,
    this.error,
    this.successMessage,
  });

  GradingConfigState copyWith({
    List<GradeConfig>? configs,
    bool? isConfigured,
    bool? isLoading,
    Object? error = _unset,
    Object? successMessage = _unset,
  }) {
    return GradingConfigState(
      configs: configs ?? this.configs,
      isConfigured: isConfigured ?? this.isConfigured,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      successMessage: identical(successMessage, _unset) ? this.successMessage : successMessage as String?,
    );
  }
}

class GradingConfigNotifier extends StateNotifier<GradingConfigState> {
  final GetGradingConfig _getGradingConfig;
  final SetupGrading _setupGrading;
  final UpdateGradingConfig _updateGradingConfig;

  GradingConfigNotifier(
    this._getGradingConfig,
    this._setupGrading,
    this._updateGradingConfig,
  ) : super(GradingConfigState());

  Future<void> loadConfig(String classId) async {
    ProviderLogger.instance.debug('loadConfig called for classId: $classId');
    state = state.copyWith(isLoading: state.configs.isEmpty, error: null);
    ProviderLogger.instance.debug('Loading grading config...');
    final result = await _getGradingConfig(classId);
    result.fold(
      (failure) {
        ProviderLogger.instance.debug('loadConfig failed: ${AppErrorMapper.fromFailure(failure)}');
        state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure));
      },
      (configs) {
        ProviderLogger.instance.debug('loadConfig success - configs count: ${configs.length}');
        ProviderLogger.instance.debug('configs data: $configs');
        ProviderLogger.instance.debug('isConfigured will be set to: ${configs.isNotEmpty}');
        state = state.copyWith(
          isLoading: false,
          configs: configs,
          isConfigured: configs.isNotEmpty,
        );
        ProviderLogger.instance.debug('State updated - isConfigured: ${state.isConfigured}, configs count: ${state.configs.length}');
      },
    );
  }

  Future<void> setupGrading(SetupGradingParams params) async {
    state = state.copyWith(error: null, successMessage: null);
    final result = await _setupGrading(params);
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
      ),
      (_) => state = state.copyWith(
        isConfigured: true,
        successMessage: 'Grading configured',
      ),
    );
  }

  Future<void> updateConfig({
    required String classId,
    required List<Map<String, dynamic>> configs,
  }) async {
    state = state.copyWith(error: null, successMessage: null);
    final result = await _updateGradingConfig(classId: classId, configs: configs);
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
      ),
      (_) => state = state.copyWith(
        successMessage: 'Grading config updated',
      ),
    );
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }

  /// Reset to clean loading state. Call before the first build of a new class
  /// so stale "not configured" state from a previous class never renders.
  void reset() {
    state = GradingConfigState();
  }
}

final gradingConfigProvider = StateNotifierProvider<GradingConfigNotifier, GradingConfigState>((ref) {
  return GradingConfigNotifier(
    sl<GetGradingConfig>(),
    sl<SetupGrading>(),
    sl<UpdateGradingConfig>(),
  );
});
