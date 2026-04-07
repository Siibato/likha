import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/services/school_setup_service.dart';
import 'package:likha/domain/setup/entities/school_config.dart';
import 'package:likha/injection_container.dart';

class SchoolSetupState {
  final bool isLoading;
  final String? error;
  final SchoolConfig? connectedConfig;

  const SchoolSetupState({
    this.isLoading = false,
    this.error,
    this.connectedConfig,
  });

  bool get isConnected => connectedConfig != null;

  SchoolSetupState copyWith({
    bool? isLoading,
    String? error,
    SchoolConfig? connectedConfig,
    bool clearError = false,
    bool clearConfig = false,
  }) {
    return SchoolSetupState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      connectedConfig: clearConfig ? null : (connectedConfig ?? this.connectedConfig),
    );
  }
}

class SchoolSetupNotifier extends StateNotifier<SchoolSetupState> {
  final SchoolSetupService _service;

  SchoolSetupNotifier(this._service) : super(const SchoolSetupState());

  Future<void> connectViaQr(String base64Payload) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _service.resolveQrPayload(base64Payload);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (config) => state = state.copyWith(
        isLoading: false,
        connectedConfig: config,
        clearError: true,
      ),
    );
  }

  Future<void> connectViaCode(String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _service.resolveShortCode(code);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (config) => state = state.copyWith(
        isLoading: false,
        connectedConfig: config,
        clearError: true,
      ),
    );
  }

  Future<void> connectManual(String url, String name) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _service.connectManual(url, name);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (config) => state = state.copyWith(
        isLoading: false,
        connectedConfig: config,
        clearError: true,
      ),
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final schoolSetupProvider =
    StateNotifierProvider<SchoolSetupNotifier, SchoolSetupState>(
  (ref) => SchoolSetupNotifier(sl<SchoolSetupService>()),
);
