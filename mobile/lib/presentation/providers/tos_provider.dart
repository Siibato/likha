import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/data/models/tos/melcs_model.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/domain/tos/usecases/add_competency.dart';
import 'package:likha/domain/tos/usecases/bulk_add_competencies.dart';
import 'package:likha/domain/tos/usecases/create_tos.dart';
import 'package:likha/domain/tos/usecases/delete_competency.dart';
import 'package:likha/domain/tos/usecases/delete_tos.dart';
import 'package:likha/domain/tos/usecases/get_tos_detail.dart';
import 'package:likha/domain/tos/usecases/get_tos_list.dart';
import 'package:likha/domain/tos/usecases/search_melcs.dart';
import 'package:likha/domain/tos/usecases/update_competency.dart';
import 'package:likha/domain/tos/usecases/update_tos.dart';
import 'package:likha/injection_container.dart';

const _kMelcPageSize = 30;

class TosState {
  final List<TableOfSpecifications> tosList;
  final TableOfSpecifications? currentTos;
  final List<TosCompetency> competencies;
  final List<MelcEntryModel> melcResults;
  final bool isLoading;
  final bool isMelcSearching;
  final bool isLoadingMore;
  final bool melcHasMore;
  final int melcPage;
  final String? error;
  final String? successMessage;
  final String? selectedGrade;
  final String? selectedSubject;

  TosState({
    this.tosList = const [],
    this.currentTos,
    this.competencies = const [],
    this.melcResults = const [],
    this.isLoading = false,
    this.isMelcSearching = false,
    this.isLoadingMore = false,
    this.melcHasMore = true,
    this.melcPage = 0,
    this.error,
    this.successMessage,
    this.selectedGrade,
    this.selectedSubject,
  });

  TosState copyWith({
    List<TableOfSpecifications>? tosList,
    TableOfSpecifications? currentTos,
    List<TosCompetency>? competencies,
    List<MelcEntryModel>? melcResults,
    bool? isLoading,
    bool? isMelcSearching,
    bool? isLoadingMore,
    bool? melcHasMore,
    int? melcPage,
    String? error,
    String? successMessage,
    String? selectedGrade,
    String? selectedSubject,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearTos = false,
    bool clearGrade = false,
    bool clearSubject = false,
  }) {
    return TosState(
      tosList: tosList ?? this.tosList,
      currentTos: clearTos ? null : (currentTos ?? this.currentTos),
      competencies: competencies ?? this.competencies,
      melcResults: melcResults ?? this.melcResults,
      isLoading: isLoading ?? this.isLoading,
      isMelcSearching: isMelcSearching ?? this.isMelcSearching,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      melcHasMore: melcHasMore ?? this.melcHasMore,
      melcPage: melcPage ?? this.melcPage,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      selectedGrade: clearGrade ? null : (selectedGrade ?? this.selectedGrade),
      selectedSubject: clearSubject ? null : (selectedSubject ?? this.selectedSubject),
    );
  }
}

class TosNotifier extends StateNotifier<TosState> {
  TosNotifier() : super(TosState());

  Future<void> loadTosList(String classId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await sl<GetTosList>().call(classId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (list) => state = state.copyWith(isLoading: false, tosList: list),
    );
  }

  Future<void> loadTosDetail(String tosId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await sl<GetTosDetail>().call(tosId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (data) => state = state.copyWith(
        isLoading: false,
        currentTos: data.$1,
        competencies: data.$2,
      ),
    );
  }

  Future<TableOfSpecifications?> createTos(String classId, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await sl<CreateTos>().call(classId: classId, data: data);
    TableOfSpecifications? created;
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (tos) {
        created = tos;
        state = state.copyWith(
          isLoading: false,
          tosList: [tos, ...state.tosList],
          successMessage: 'TOS created',
        );
      },
    );
    return created;
  }

  Future<void> updateTos(String tosId, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await sl<UpdateTos>().call(tosId: tosId, data: data);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (tos) {
        final updated = state.tosList.map((t) => t.id == tosId ? tos : t).toList();
        state = state.copyWith(
          isLoading: false,
          tosList: updated,
          currentTos: tos,
          successMessage: 'TOS updated',
        );
      },
    );
  }

  Future<void> deleteTos(String tosId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await sl<DeleteTos>().call(tosId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (_) {
        final filtered = state.tosList.where((t) => t.id != tosId).toList();
        state = state.copyWith(
          isLoading: false,
          tosList: filtered,
          clearTos: true,
          successMessage: 'TOS deleted',
        );
      },
    );
  }

  Future<void> addCompetency(String tosId, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await sl<AddCompetency>().call(tosId: tosId, data: data);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (comp) => state = state.copyWith(
        isLoading: false,
        competencies: [...state.competencies, comp],
        successMessage: 'Competency added',
      ),
    );
  }

  Future<void> updateCompetency(String competencyId, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await sl<UpdateCompetency>().call(competencyId: competencyId, data: data);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (comp) {
        final updated = state.competencies.map((c) => c.id == competencyId ? comp : c).toList();
        state = state.copyWith(
          isLoading: false,
          competencies: updated,
          successMessage: 'Competency updated',
        );
      },
    );
  }

  Future<void> deleteCompetency(String competencyId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await sl<DeleteCompetency>().call(competencyId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (_) {
        final filtered = state.competencies.where((c) => c.id != competencyId).toList();
        state = state.copyWith(
          isLoading: false,
          competencies: filtered,
          successMessage: 'Competency deleted',
        );
      },
    );
  }

  Future<void> bulkAddCompetencies(String tosId, List<Map<String, dynamic>> competencies) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await sl<BulkAddCompetencies>().call(tosId: tosId, competencies: competencies);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (added) => state = state.copyWith(
        isLoading: false,
        competencies: [...state.competencies, ...added],
        successMessage: '${added.length} competencies added',
      ),
    );
  }

  // Stored so loadMoreMelcs can re-use the same filters/query.
  SearchMelcsParams? _lastMelcParams;

  Future<void> searchMelcs(SearchMelcsParams params) async {
    _lastMelcParams = params.copyWith(limit: _kMelcPageSize, offset: 0);
    state = state.copyWith(
      isMelcSearching: true,
      clearError: true,
      melcPage: 0,
      melcHasMore: true,
      melcResults: [],
    );
    final result = await sl<SearchMelcs>().call(_lastMelcParams!);
    result.fold(
      (failure) => state = state.copyWith(isMelcSearching: false, error: failure.message),
      (results) => state = state.copyWith(
        isMelcSearching: false,
        melcResults: results,
        melcPage: 1,
        melcHasMore: results.length >= _kMelcPageSize,
      ),
    );
  }

  Future<void> loadMoreMelcs() async {
    if (!state.melcHasMore || state.isLoadingMore || state.isMelcSearching) return;
    if (_lastMelcParams == null) return;
    final nextParams = _lastMelcParams!.copyWith(
      limit: _kMelcPageSize,
      offset: state.melcPage * _kMelcPageSize,
    );
    state = state.copyWith(isLoadingMore: true);
    final result = await sl<SearchMelcs>().call(nextParams);
    result.fold(
      (failure) => state = state.copyWith(isLoadingMore: false, error: failure.message),
      (results) => state = state.copyWith(
        isLoadingMore: false,
        melcResults: [...state.melcResults, ...results],
        melcPage: state.melcPage + 1,
        melcHasMore: results.length >= _kMelcPageSize,
      ),
    );
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  void clearMelcResults() {
    state = state.copyWith(melcResults: []);
  }

  void setMelcFilters({String? grade, String? subject, bool clearGrade = false, bool clearSubject = false}) {
    state = state.copyWith(
      selectedGrade: grade,
      selectedSubject: subject,
      clearGrade: clearGrade,
      clearSubject: clearSubject,
    );
  }
}

final tosProvider = StateNotifierProvider<TosNotifier, TosState>(
  (ref) => TosNotifier(),
);
