import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/grading/entities/general_average.dart';
import 'package:likha/domain/grading/usecases/get_general_averages.dart';
import 'package:likha/injection_container.dart';

class GeneralAverageState {
  final GeneralAverageResponse? response;
  final bool isLoading;
  final String? error;

  GeneralAverageState({this.response, this.isLoading = false, this.error});

  GeneralAverageState copyWith({
    GeneralAverageResponse? response,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return GeneralAverageState(
      response: response ?? this.response,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GeneralAverageNotifier extends StateNotifier<GeneralAverageState> {
  GeneralAverageNotifier() : super(GeneralAverageState());

  Future<void> loadGeneralAverages(String classId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await sl<GetGeneralAverages>().call(classId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (data) => state = state.copyWith(isLoading: false, response: data),
    );
  }
}

final generalAverageProvider =
    StateNotifierProvider<GeneralAverageNotifier, GeneralAverageState>(
  (ref) => GeneralAverageNotifier(),
);
