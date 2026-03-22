import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/grading/entities/general_average.dart';
import 'package:likha/domain/grading/entities/sf9.dart';
import 'package:likha/domain/grading/usecases/get_general_averages.dart';
import 'package:likha/domain/grading/usecases/get_sf10.dart';
import 'package:likha/domain/grading/usecases/get_sf9.dart';
import 'package:likha/injection_container.dart';

class Sf9State {
  final List<StudentGeneralAverage> students;
  final Sf9Response? currentSf9;
  final bool isLoading;
  final String? error;

  Sf9State({
    this.students = const [],
    this.currentSf9,
    this.isLoading = false,
    this.error,
  });

  Sf9State copyWith({
    List<StudentGeneralAverage>? students,
    Sf9Response? currentSf9,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearSf9 = false,
  }) {
    return Sf9State(
      students: students ?? this.students,
      currentSf9: clearSf9 ? null : (currentSf9 ?? this.currentSf9),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class Sf9Notifier extends StateNotifier<Sf9State> {
  Sf9Notifier() : super(Sf9State());

  Future<void> loadStudents(String classId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await sl<GetGeneralAverages>().call(classId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (data) => state = state.copyWith(isLoading: false, students: data.students),
    );
  }

  Future<void> loadSf9(String classId, String studentId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSf9: true);
    final result = await sl<GetSf9>().call(GetSf9Params(
      classId: classId,
      studentId: studentId,
    ));
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (sf9) => state = state.copyWith(isLoading: false, currentSf9: sf9),
    );
  }

  Future<void> loadSf10(String classId, String studentId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSf9: true);
    final result = await sl<GetSf10>().call(GetSf10Params(
      classId: classId,
      studentId: studentId,
    ));
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (sf10) => state = state.copyWith(isLoading: false, currentSf9: sf10),
    );
  }
}

final sf9Provider = StateNotifierProvider<Sf9Notifier, Sf9State>(
  (ref) => Sf9Notifier(),
);
