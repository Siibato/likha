import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/domain/setup/entities/school_settings.dart';
import 'package:likha/domain/setup/usecases/get_school_settings.dart';
import 'package:likha/domain/setup/usecases/update_school_settings.dart';
import 'package:likha/domain/setup/usecases/update_school_code.dart';
import 'package:likha/injection_container.dart';

class SchoolSettingsState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final SchoolSettings? settings;

  const SchoolSettingsState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.settings,
  });

  SchoolSettingsState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    SchoolSettings? settings,
    bool clearError = false,
    bool clearSettings = false,
  }) {
    return SchoolSettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      settings: clearSettings ? null : (settings ?? this.settings),
    );
  }
}

class SchoolSettingsNotifier extends StateNotifier<SchoolSettingsState> {
  final GetSchoolSettings _getSchoolSettings;
  final UpdateSchoolSettings _updateSchoolSettings;
  final UpdateSchoolCode _updateSchoolCode;
  final DataEventBus _dataEventBus;

  SchoolSettingsNotifier(
    this._getSchoolSettings,
    this._updateSchoolSettings,
    this._updateSchoolCode,
    this._dataEventBus,
  ) : super(const SchoolSettingsState()) {
    _dataEventBus.onSchoolSettingsChanged.listen((_) {
      loadSchoolSettings(skipBackgroundRefresh: true);
    });
  }

  Future<void> loadSchoolSettings({bool skipBackgroundRefresh = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getSchoolSettings(
      skipBackgroundRefresh: skipBackgroundRefresh,
    );
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure) ?? 'Something went wrong. Try again later.',
      ),
      (settings) => state = state.copyWith(
        isLoading: false,
        settings: settings,
        clearError: true,
      ),
    );
  }

  Future<bool> updateSchoolSettings({
    required String schoolName,
    required String schoolRegion,
    required String schoolDivision,
    required String schoolYear,
    required String schoolCode,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    final result = await _updateSchoolSettings(
      schoolName: schoolName,
      schoolRegion: schoolRegion,
      schoolDivision: schoolDivision,
      schoolYear: schoolYear,
      schoolCode: schoolCode,
    );
    return result.fold(
      (failure) {
        state = state.copyWith(
          isSaving: false,
          error: AppErrorMapper.fromFailure(failure) ?? 'Something went wrong. Try again later.',
        );
        return false;
      },
      (mutationResult) {
        state = state.copyWith(
          isSaving: false,
          settings: mutationResult.entity,
          clearError: true,
        );
        return true;
      },
    );
  }

  Future<bool> updateSchoolCode({required String schoolCode}) async {
    state = state.copyWith(isSaving: true, clearError: true);
    final result = await _updateSchoolCode(schoolCode: schoolCode);
    return result.fold(
      (failure) {
        state = state.copyWith(
          isSaving: false,
          error: AppErrorMapper.fromFailure(failure) ?? 'Something went wrong. Try again later.',
        );
        return false;
      },
      (mutationResult) {
        state = state.copyWith(
          isSaving: false,
          settings: mutationResult.entity,
          clearError: true,
        );
        return true;
      },
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final schoolSettingsProvider =
    StateNotifierProvider<SchoolSettingsNotifier, SchoolSettingsState>(
  (ref) => SchoolSettingsNotifier(
    sl<GetSchoolSettings>(),
    sl<UpdateSchoolSettings>(),
    sl<UpdateSchoolCode>(),
    sl<DataEventBus>(),
  ),
);
