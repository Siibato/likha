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
    final previousTosList = List<TableOfSpecifications>.from(state.tosList);
    final now = DateTime.now();
    final tempId = 'temp-${now.microsecondsSinceEpoch}';
    final optimistic = TableOfSpecifications(
      id: tempId,
      classId: classId,
      gradingPeriodNumber: data['grading_period_number'] is int
          ? data['grading_period_number']
          : int.tryParse(data['grading_period_number']?.toString() ?? '') ?? 1,
      title: data['title']?.toString() ?? '',
      classificationMode: data['classification_mode']?.toString() ?? 'cognitive',
      totalItems: data['total_items'] is int
          ? data['total_items']
          : int.tryParse(data['total_items']?.toString() ?? '') ?? 0,
      timeUnit: data['time_unit']?.toString() ?? 'days',
      easyPercentage: (data['easy_percentage'] as num?)?.toDouble() ?? 50.0,
      mediumPercentage: (data['medium_percentage'] as num?)?.toDouble() ?? 30.0,
      hardPercentage: (data['hard_percentage'] as num?)?.toDouble() ?? 20.0,
      rememberingPercentage: (data['remembering_percentage'] as num?)?.toDouble() ?? 16.67,
      understandingPercentage: (data['understanding_percentage'] as num?)?.toDouble() ?? 16.67,
      applyingPercentage: (data['applying_percentage'] as num?)?.toDouble() ?? 16.67,
      analyzingPercentage: (data['analyzing_percentage'] as num?)?.toDouble() ?? 16.67,
      evaluatingPercentage: (data['evaluating_percentage'] as num?)?.toDouble() ?? 16.67,
      creatingPercentage: (data['creating_percentage'] as num?)?.toDouble() ?? 16.67,
      createdAt: now,
      updatedAt: now,
    );

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
      tosList: [optimistic, ...state.tosList],
    );

    final result = await sl<CreateTos>().call(classId: classId, data: data);
    TableOfSpecifications? created;
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
        tosList: previousTosList,
      ),
      (tos) {
        created = tos;
        final updatedList = state.tosList.map((t) => t.id == tempId ? tos : t).toList();
        state = state.copyWith(
          isLoading: false,
          tosList: updatedList,
          successMessage: 'TOS created',
        );
      },
    );
    return created;
  }

  Future<void> updateTos(String tosId, Map<String, dynamic> data) async {
    final previousTosList = List<TableOfSpecifications>.from(state.tosList);
    final previousCurrentTos = state.currentTos;
    final existing = state.tosList.firstWhere(
      (t) => t.id == tosId,
      orElse: () => previousCurrentTos ?? state.tosList.firstWhere(
        (t) => t.id == tosId,
        orElse: () => TableOfSpecifications(
          id: tosId,
          classId: '',
          gradingPeriodNumber: 1,
          title: '',
          classificationMode: 'cognitive',
          totalItems: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
    );

    final optimistic = TableOfSpecifications(
      id: existing.id,
      classId: existing.classId,
      gradingPeriodNumber: data['grading_period_number'] is int
          ? data['grading_period_number']
          : existing.gradingPeriodNumber,
      title: data['title']?.toString() ?? existing.title,
      classificationMode: data['classification_mode']?.toString() ?? existing.classificationMode,
      totalItems: data['total_items'] is int
          ? data['total_items']
          : (data['total_items'] != null
              ? int.tryParse(data['total_items'].toString()) ?? existing.totalItems
              : existing.totalItems),
      timeUnit: data['time_unit']?.toString() ?? existing.timeUnit,
      easyPercentage: (data['easy_percentage'] as num?)?.toDouble() ?? existing.easyPercentage,
      mediumPercentage: (data['medium_percentage'] as num?)?.toDouble() ?? existing.mediumPercentage,
      hardPercentage: (data['hard_percentage'] as num?)?.toDouble() ?? existing.hardPercentage,
      rememberingPercentage: (data['remembering_percentage'] as num?)?.toDouble() ?? existing.rememberingPercentage,
      understandingPercentage: (data['understanding_percentage'] as num?)?.toDouble() ?? existing.understandingPercentage,
      applyingPercentage: (data['applying_percentage'] as num?)?.toDouble() ?? existing.applyingPercentage,
      analyzingPercentage: (data['analyzing_percentage'] as num?)?.toDouble() ?? existing.analyzingPercentage,
      evaluatingPercentage: (data['evaluating_percentage'] as num?)?.toDouble() ?? existing.evaluatingPercentage,
      creatingPercentage: (data['creating_percentage'] as num?)?.toDouble() ?? existing.creatingPercentage,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );

    final updatedList = state.tosList.map((t) => t.id == tosId ? optimistic : t).toList();
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
      tosList: updatedList,
      currentTos: state.currentTos?.id == tosId ? optimistic : state.currentTos,
    );

    final result = await sl<UpdateTos>().call(tosId: tosId, data: data);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
        tosList: previousTosList,
        currentTos: previousCurrentTos,
      ),
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
    final previousTosList = List<TableOfSpecifications>.from(state.tosList);
    final previousCurrentTos = state.currentTos;
    final filtered = state.tosList.where((t) => t.id != tosId).toList();

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
      tosList: filtered,
      clearTos: state.currentTos?.id == tosId,
    );

    final result = await sl<DeleteTos>().call(tosId);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
        tosList: previousTosList,
        currentTos: previousCurrentTos,
      ),
      (_) => state = state.copyWith(
        isLoading: false,
        successMessage: 'TOS deleted',
      ),
    );
  }

  Future<void> addCompetency(String tosId, Map<String, dynamic> data) async {
    final previousCompetencies = List<TosCompetency>.from(state.competencies);
    final now = DateTime.now();
    final tempId = 'temp-${now.microsecondsSinceEpoch}';
    final optimistic = TosCompetency(
      id: tempId,
      tosId: tosId,
      competencyCode: data['competency_code']?.toString(),
      competencyText: data['competency_text']?.toString() ?? '',
      timeUnitsTaught: data['time_units_taught'] is int
          ? data['time_units_taught']
          : int.tryParse(data['time_units_taught']?.toString() ?? '') ?? 0,
      orderIndex: data['order_index'] is int
          ? data['order_index']
          : int.tryParse(data['order_index']?.toString() ?? '') ?? state.competencies.length,
      easyCount: data['easy_count'] is int ? data['easy_count'] : null,
      mediumCount: data['medium_count'] is int ? data['medium_count'] : null,
      hardCount: data['hard_count'] is int ? data['hard_count'] : null,
      rememberingCount: data['remembering_count'] is int ? data['remembering_count'] : null,
      understandingCount: data['understanding_count'] is int ? data['understanding_count'] : null,
      applyingCount: data['applying_count'] is int ? data['applying_count'] : null,
      analyzingCount: data['analyzing_count'] is int ? data['analyzing_count'] : null,
      evaluatingCount: data['evaluating_count'] is int ? data['evaluating_count'] : null,
      creatingCount: data['creating_count'] is int ? data['creating_count'] : null,
      createdAt: now,
      updatedAt: now,
    );

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
      competencies: [...state.competencies, optimistic],
    );

    final result = await sl<AddCompetency>().call(tosId: tosId, data: data);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
        competencies: previousCompetencies,
      ),
      (comp) {
        final updated = state.competencies.map((c) => c.id == tempId ? comp : c).toList();
        state = state.copyWith(
          isLoading: false,
          competencies: updated,
          successMessage: 'Competency added',
        );
      },
    );
  }

  Future<void> updateCompetency(String competencyId, Map<String, dynamic> data) async {
    final previousCompetencies = List<TosCompetency>.from(state.competencies);
    final existing = state.competencies.firstWhere(
      (c) => c.id == competencyId,
      orElse: () => TosCompetency(
        id: competencyId,
        tosId: state.currentTos?.id ?? '',
        competencyText: data['competency_text']?.toString() ?? '',
        timeUnitsTaught: 0,
        orderIndex: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final optimistic = TosCompetency(
      id: existing.id,
      tosId: existing.tosId,
      competencyCode: data['competency_code']?.toString() ?? existing.competencyCode,
      competencyText: data['competency_text']?.toString() ?? existing.competencyText,
      timeUnitsTaught: data['time_units_taught'] is int
          ? data['time_units_taught']
          : existing.timeUnitsTaught,
      orderIndex: data['order_index'] is int
          ? data['order_index']
          : existing.orderIndex,
      easyCount: data['easy_count'] is int ? data['easy_count'] : existing.easyCount,
      mediumCount: data['medium_count'] is int ? data['medium_count'] : existing.mediumCount,
      hardCount: data['hard_count'] is int ? data['hard_count'] : existing.hardCount,
      rememberingCount: data['remembering_count'] is int ? data['remembering_count'] : existing.rememberingCount,
      understandingCount: data['understanding_count'] is int ? data['understanding_count'] : existing.understandingCount,
      applyingCount: data['applying_count'] is int ? data['applying_count'] : existing.applyingCount,
      analyzingCount: data['analyzing_count'] is int ? data['analyzing_count'] : existing.analyzingCount,
      evaluatingCount: data['evaluating_count'] is int ? data['evaluating_count'] : existing.evaluatingCount,
      creatingCount: data['creating_count'] is int ? data['creating_count'] : existing.creatingCount,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );

    final updated = state.competencies.map((c) => c.id == competencyId ? optimistic : c).toList();
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
      competencies: updated,
    );

    final result = await sl<UpdateCompetency>().call(competencyId: competencyId, data: data);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
        competencies: previousCompetencies,
      ),
      (comp) {
        final updatedList = state.competencies.map((c) => c.id == competencyId ? comp : c).toList();
        state = state.copyWith(
          isLoading: false,
          competencies: updatedList,
          successMessage: 'Competency updated',
        );
      },
    );
  }

  Future<void> deleteCompetency(String competencyId) async {
    final previousCompetencies = List<TosCompetency>.from(state.competencies);
    final filtered = state.competencies.where((c) => c.id != competencyId).toList();

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
      competencies: filtered,
    );

    final result = await sl<DeleteCompetency>().call(competencyId);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
        competencies: previousCompetencies,
      ),
      (_) => state = state.copyWith(
        isLoading: false,
        successMessage: 'Competency deleted',
      ),
    );
  }

  Future<void> bulkAddCompetencies(String tosId, List<Map<String, dynamic>> competencies) async {
    final previousCompetencies = List<TosCompetency>.from(state.competencies);
    final now = DateTime.now();
    final optimisticList = competencies.asMap().entries.map((entry) {
      final idx = entry.key;
      final data = entry.value;
      return TosCompetency(
        id: 'temp-bulk-$tosId-$idx-${now.microsecondsSinceEpoch}',
        tosId: tosId,
        competencyCode: data['competency_code']?.toString(),
        competencyText: data['competency_text']?.toString() ?? '',
        timeUnitsTaught: data['time_units_taught'] is int
            ? data['time_units_taught']
            : int.tryParse(data['time_units_taught']?.toString() ?? '') ?? 0,
        orderIndex: data['order_index'] is int
            ? data['order_index']
            : (previousCompetencies.length + idx),
        easyCount: data['easy_count'] is int ? data['easy_count'] : null,
        mediumCount: data['medium_count'] is int ? data['medium_count'] : null,
        hardCount: data['hard_count'] is int ? data['hard_count'] : null,
        rememberingCount: data['remembering_count'] is int ? data['remembering_count'] : null,
        understandingCount: data['understanding_count'] is int ? data['understanding_count'] : null,
        applyingCount: data['applying_count'] is int ? data['applying_count'] : null,
        analyzingCount: data['analyzing_count'] is int ? data['analyzing_count'] : null,
        evaluatingCount: data['evaluating_count'] is int ? data['evaluating_count'] : null,
        creatingCount: data['creating_count'] is int ? data['creating_count'] : null,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
      competencies: [...state.competencies, ...optimisticList],
    );

    final result = await sl<BulkAddCompetencies>().call(tosId: tosId, competencies: competencies);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
        competencies: previousCompetencies,
      ),
      (added) {
        final tempIds = optimisticList.map((c) => c.id).toSet();
        final withoutTemps = state.competencies.where((c) => !tempIds.contains(c.id)).toList();
        state = state.copyWith(
          isLoading: false,
          competencies: [...withoutTemps, ...added],
          successMessage: '${added.length} competencies added',
        );
      },
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
