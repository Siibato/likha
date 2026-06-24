import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/classes/usecases/search_students.dart';
import 'package:likha/injection_container.dart';

class StudentSearchState {
  final List<User> searchResults;
  final bool isLoading;
  final String? error;

  StudentSearchState({
    this.searchResults = const [],
    this.isLoading = false,
    this.error,
  });

  StudentSearchState copyWith({
    List<User>? searchResults,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearSearch = false,
  }) {
    return StudentSearchState(
      searchResults: clearSearch ? const [] : (searchResults ?? this.searchResults),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class StudentSearchNotifier extends StateNotifier<StudentSearchState> {
  final SearchStudents _searchStudents;

  StudentSearchNotifier(this._searchStudents) : super(StudentSearchState());

  Future<void> searchStudents({String? query}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _searchStudents(query: query);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (students) => state = state.copyWith(
        isLoading: false,
        searchResults: students,
      ),
    );
  }

  void clearSearch() {
    state = state.copyWith(clearSearch: true);
  }
}

final studentSearchProvider = StateNotifierProvider<StudentSearchNotifier, StudentSearchState>((ref) {
  return StudentSearchNotifier(sl<SearchStudents>());
});
