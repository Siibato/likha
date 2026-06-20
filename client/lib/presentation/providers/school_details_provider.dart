import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/domain/setup/entities/school_details.dart';
import 'package:likha/domain/setup/usecases/get_school_details.dart';
import 'package:likha/domain/setup/usecases/update_school_details.dart';
import 'package:likha/domain/setup/usecases/update_school_code.dart';
import 'package:likha/injection_container.dart';

class SchoolDetailsState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final SchoolDetails? settings;

  const SchoolDetailsState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.settings,
  });

  SchoolDetailsState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    SchoolDetails? settings,
    bool clearError = false,
    bool clearSettings = false,
  }) {
    return SchoolDetailsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      settings: clearSettings ? null : (settings ?? this.settings),
    );
  }
}

class SchoolDetailsNotifier extends StateNotifier<SchoolDetailsState> {
  final GetSchoolDetails _getSchoolDetails;
  final UpdateSchoolDetails _updateSchoolDetails;
  final UpdateSchoolCode _updateSchoolCode;
  final DataEventBus _dataEventBus;

  SchoolDetailsNotifier(
    this._getSchoolDetails,
    this._updateSchoolDetails,
    this._updateSchoolCode,
    this._dataEventBus,
  ) : super(const SchoolDetailsState()) {
    _dataEventBus.onSchoolDetailsChanged.listen((_) {
      loadSchoolDetails(skipBackgroundRefresh: true);
    });
  }

  Future<void> loadSchoolDetails({bool skipBackgroundRefresh = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getSchoolDetails(
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

  Future<bool> updateSchoolDetails({
    required String schoolName,
    required String schoolRegion,
    required String schoolDivision,
    required String schoolYear,
    required String schoolCode,
    String? schoolDistrict,
    String? schoolHeadName,
    String? schoolHeadPosition,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    final result = await _updateSchoolDetails(
      schoolName: schoolName,
      schoolRegion: schoolRegion,
      schoolDivision: schoolDivision,
      schoolYear: schoolYear,
      schoolCode: schoolCode,
      schoolDistrict: schoolDistrict,
      schoolHeadName: schoolHeadName,
      schoolHeadPosition: schoolHeadPosition,
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

final schoolDetailsProvider =
    StateNotifierProvider<SchoolDetailsNotifier, SchoolDetailsState>(
  (ref) => SchoolDetailsNotifier(
    sl<GetSchoolDetails>(),
    sl<UpdateSchoolDetails>(),
    sl<UpdateSchoolCode>(),
    sl<DataEventBus>(),
  ),
);
