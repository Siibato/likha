import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/logging/provider_logger.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/domain/grading/entities/quarterly_grade.dart';
import 'package:likha/domain/grading/usecases/clear_score_override.dart';
import 'package:likha/domain/grading/usecases/compute_grades.dart';
import 'package:likha/domain/grading/usecases/create_grade_item.dart';
import 'package:likha/domain/grading/usecases/delete_grade_item.dart';
import 'package:likha/domain/grading/usecases/get_grade_items.dart';
import 'package:likha/domain/grading/usecases/get_grade_summary.dart';
import 'package:likha/domain/grading/usecases/get_grading_config.dart';
import 'package:likha/domain/grading/usecases/get_quarterly_grades.dart';
import 'package:likha/domain/grading/usecases/get_scores_by_item.dart';
import 'package:likha/domain/grading/usecases/save_scores.dart';
import 'package:likha/domain/grading/usecases/set_score_override.dart';
import 'package:likha/domain/grading/usecases/setup_grading.dart';
import 'package:likha/domain/grading/usecases/update_grading_config.dart';
import 'package:likha/domain/grading/usecases/update_quarterly_grade.dart';
import 'package:likha/domain/assessments/usecases/get_assessments.dart';
import 'package:likha/domain/assignments/usecases/get_assignments.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';
import 'package:likha/injection_container.dart';

const _unset = Object();

// ===== Grading Config =====

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
    state = state.copyWith(isLoading: true, error: null);
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
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await _setupGrading(params);
    String? errorMsg;
    result.fold(
      (failure) => errorMsg = AppErrorMapper.fromFailure(failure),
      (_) {},
    );
    if (errorMsg != null) {
      state = state.copyWith(isLoading: false, error: errorMsg);
      return;
    }
    final configResult = await _getGradingConfig(params.classId);
    configResult.fold(
      (_) => state = state.copyWith(
        isLoading: false,
        isConfigured: true, // write succeeded even if re-read failed
        successMessage: 'Grading configured',
      ),
      (configs) => state = state.copyWith(
        isLoading: false,
        isConfigured: true,
        configs: configs,
        successMessage: 'Grading configured',
      ),
    );
  }

  Future<void> updateConfig({
    required String classId,
    required List<Map<String, dynamic>> configs,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await _updateGradingConfig(classId: classId, configs: configs);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (_) => state = state.copyWith(
        isLoading: false,
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

// ===== Grade Items =====

class GradeItemsState {
  final List<GradeItem> items;
  final int currentQuarter;
  final String currentComponent;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  GradeItemsState({
    this.items = const [],
    this.currentQuarter = 1,
    this.currentComponent = '',
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  GradeItemsState copyWith({
    List<GradeItem>? items,
    int? currentQuarter,
    String? currentComponent,
    bool? isLoading,
    Object? error = _unset,
    Object? successMessage = _unset,
  }) {
    return GradeItemsState(
      items: items ?? this.items,
      currentQuarter: currentQuarter ?? this.currentQuarter,
      currentComponent: currentComponent ?? this.currentComponent,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      successMessage: identical(successMessage, _unset) ? this.successMessage : successMessage as String?,
    );
  }
}

class GradeItemsNotifier extends StateNotifier<GradeItemsState> {
  final GetGradeItems _getGradeItems;
  final CreateGradeItem _createGradeItem;
  final DeleteGradeItem _deleteGradeItem;

  GradeItemsNotifier(
    this._getGradeItems,
    this._createGradeItem,
    this._deleteGradeItem,
  ) : super(GradeItemsState());

  Future<void> loadItems(String classId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getGradeItems(GetGradeItemsParams(
      classId: classId,
      quarter: state.currentQuarter,
      component: state.currentComponent.isEmpty ? null : state.currentComponent,
    ));
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (items) => state = state.copyWith(isLoading: false, items: items),
    );
  }

  Future<void> createItem(String classId, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await _createGradeItem(classId: classId, data: data);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (item) => state = state.copyWith(
        isLoading: false,
        items: [...state.items, item],
        successMessage: 'Grade item created',
      ),
    );
  }

  Future<void> deleteItem(String id) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await _deleteGradeItem(id);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (_) => state = state.copyWith(
        isLoading: false,
        items: state.items.where((i) => i.id != id).toList(),
        successMessage: 'Grade item deleted',
      ),
    );
  }

  String _toGradeComponent(String c) {
    switch (c) {
      case 'written_work': return 'ww';
      case 'performance_task': return 'pt';
      case 'quarterly_assessment': return 'qa';
      default: return c;
    }
  }

  Future<void> backfillFromActivities(String classId, int quarter) async {
    final existingSourceIds = state.items
        .where((i) => i.sourceId != null)
        .map((i) => i.sourceId!)
        .toSet();

    final assessmentResult = await sl<GetAssessments>()(classId);
    assessmentResult.fold((_) {}, (assessments) {
      for (final a in assessments) {
        if (a.quarter == quarter && a.component != null && !existingSourceIds.contains(a.id)) {
          sl<GradingRepository>().createGradeItem(
            classId: classId,
            data: {
              'title': a.title,
              'component': _toGradeComponent(a.component!),
              'quarter': quarter,
              'total_points': a.totalPoints.toDouble(),
              'is_departmental_exam': false,
              'source_type': 'assessment',
              'source_id': a.id,
              'order_index': 0,
            },
          ).then((res) {
            res.fold((_) {}, (item) {
              state = state.copyWith(items: [...state.items, item]);
            });
          });
        }
      }
    });

    final assignmentResult = await sl<GetAssignments>()(classId);
    assignmentResult.fold((_) {}, (assignments) {
      for (final a in assignments) {
        if (a.quarter == quarter && a.component != null && !existingSourceIds.contains(a.id)) {
          sl<GradingRepository>().createGradeItem(
            classId: classId,
            data: {
              'title': a.title,
              'component': _toGradeComponent(a.component!),
              'quarter': quarter,
              'total_points': a.totalPoints.toDouble(),
              'is_departmental_exam': false,
              'source_type': 'assignment',
              'source_id': a.id,
              'order_index': 0,
            },
          ).then((res) {
            res.fold((_) {}, (item) {
              state = state.copyWith(items: [...state.items, item]);
            });
          });
        }
      }
    });
  }

  void setQuarter(int quarter) {
    state = state.copyWith(currentQuarter: quarter);
  }

  void setComponent(String component) {
    state = state.copyWith(currentComponent: component);
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

// ===== Grade Scores =====

class GradeScoresState {
  final Map<String, List<GradeScore>> scoresByItem;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  GradeScoresState({
    this.scoresByItem = const {},
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  GradeScoresState copyWith({
    Map<String, List<GradeScore>>? scoresByItem,
    bool? isLoading,
    Object? error = _unset,
    Object? successMessage = _unset,
  }) {
    return GradeScoresState(
      scoresByItem: scoresByItem ?? this.scoresByItem,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      successMessage: identical(successMessage, _unset) ? this.successMessage : successMessage as String?,
    );
  }
}

class GradeScoresNotifier extends StateNotifier<GradeScoresState> {
  final GetScoresByItem _getScoresByItem;
  final SaveScores _saveScores;
  final SetScoreOverride _setScoreOverride;
  final ClearScoreOverride _clearScoreOverride;

  GradeScoresNotifier(
    this._getScoresByItem,
    this._saveScores,
    this._setScoreOverride,
    this._clearScoreOverride,
  ) : super(GradeScoresState());

  Future<void> loadScoresForItems(List<String> gradeItemIds) async {
    state = state.copyWith(isLoading: true, error: null);
    final Map<String, List<GradeScore>> allScores = {};

    for (final itemId in gradeItemIds) {
      final result = await _getScoresByItem(itemId);
      result.fold(
        (failure) {
          state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure));
          return;
        },
        (scores) => allScores[itemId] = scores,
      );
      if (state.error != null) return;
    }

    state = state.copyWith(isLoading: false, scoresByItem: allScores);
  }

  Future<void> saveScores(
    String gradeItemId,
    List<Map<String, dynamic>> scores,
  ) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await _saveScores(gradeItemId: gradeItemId, scores: scores);
    String? errorMsg;
    result.fold(
      (failure) => errorMsg = AppErrorMapper.fromFailure(failure),
      (_) {},
    );
    if (errorMsg != null) {
      state = state.copyWith(isLoading: false, error: errorMsg);
      return;
    }
    // Reload fresh scores for just this item so the grid cell reflects the
    // saved value immediately (without a full reload).
    final fresh = await _getScoresByItem(gradeItemId);
    final updated = Map<String, List<GradeScore>>.from(state.scoresByItem);
    fresh.fold((_) {}, (newScores) => updated[gradeItemId] = newScores);
    state = state.copyWith(
      isLoading: false,
      scoresByItem: updated,
      successMessage: 'Scores saved',
    );
  }

  Future<void> setOverride(String scoreId, double overrideScore) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await _setScoreOverride(
      scoreId: scoreId,
      overrideScore: overrideScore,
    );
    String? errorMsg;
    result.fold(
      (failure) => errorMsg = AppErrorMapper.fromFailure(failure),
      (_) {},
    );
    if (errorMsg != null) {
      state = state.copyWith(isLoading: false, error: errorMsg);
      return;
    }
    // Find which item this score belongs to and reload its scores so the
    // override is visible in the grid immediately.
    final itemId = state.scoresByItem.entries
        .where((e) => e.value.any((s) => s.id == scoreId))
        .map((e) => e.key)
        .firstOrNull;
    if (itemId != null) {
      final fresh = await _getScoresByItem(itemId);
      final updated = Map<String, List<GradeScore>>.from(state.scoresByItem);
      fresh.fold((_) {}, (newScores) => updated[itemId] = newScores);
      state = state.copyWith(
        isLoading: false,
        scoresByItem: updated,
        successMessage: 'Score override applied',
      );
    } else {
      state = state.copyWith(isLoading: false, successMessage: 'Score override applied');
    }
  }

  Future<void> clearOverride(String scoreId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await _clearScoreOverride(scoreId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (_) => state = state.copyWith(
        isLoading: false,
        successMessage: 'Score override cleared',
      ),
    );
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

// ===== Quarterly Grades =====

class QuarterlyGradesState {
  final List<QuarterlyGrade> grades;
  final List<Map<String, dynamic>>? summary;
  final bool isLoading;
  final String? error;

  QuarterlyGradesState({
    this.grades = const [],
    this.summary,
    this.isLoading = false,
    this.error,
  });

  QuarterlyGradesState copyWith({
    List<QuarterlyGrade>? grades,
    Object? summary = _unset,
    bool? isLoading,
    Object? error = _unset,
  }) {
    return QuarterlyGradesState(
      grades: grades ?? this.grades,
      summary: identical(summary, _unset) ? this.summary : summary as List<Map<String, dynamic>>?,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

class QuarterlyGradesNotifier extends StateNotifier<QuarterlyGradesState> {
  final GetQuarterlyGrades _getQuarterlyGrades;
  final ComputeGrades _computeGrades;
  final GetGradeSummary _getGradeSummary;
  final UpdateQuarterlyGrade _updateQuarterlyGrade;

  QuarterlyGradesNotifier(
    this._getQuarterlyGrades,
    this._computeGrades,
    this._getGradeSummary,
    this._updateQuarterlyGrade,
  ) : super(QuarterlyGradesState());

  Future<void> loadGrades(String classId, int quarter) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getQuarterlyGrades(
      classId: classId,
      quarter: quarter,
    );
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (grades) => state = state.copyWith(isLoading: false, grades: grades),
    );
  }

  Future<void> computeGrades(String classId, int quarter) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _computeGrades(classId: classId, quarter: quarter);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (_) => state = state.copyWith(isLoading: false),
    );
  }

  Future<void> loadSummary(String classId, int quarter) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getGradeSummary(classId: classId, quarter: quarter);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (summary) => state = state.copyWith(isLoading: false, summary: summary),
    );
  }

  Future<void> updateQuarterlyGrade({
    required String classId,
    required String studentId,
    required int quarter,
    required int transmutedGrade,
  }) async {
    final result = await _updateQuarterlyGrade(
      classId: classId,
      studentId: studentId,
      quarter: quarter,
      transmutedGrade: transmutedGrade,
    );
    result.fold(
      (failure) => state = state.copyWith(error: AppErrorMapper.fromFailure(failure)),
      (_) {
        // Optimistically update the summary in state if loaded
        final summary = state.summary;
        if (summary != null) {
          final updated = summary.map((row) {
            if (row['student_id'] == studentId) {
              return {...row, 'quarterly_grade': transmutedGrade.toDouble()};
            }
            return row;
          }).toList();
          state = state.copyWith(summary: updated);
        }
      },
    );
  }
}

// ===== Providers =====

final gradingConfigProvider = StateNotifierProvider<GradingConfigNotifier, GradingConfigState>((ref) {
  return GradingConfigNotifier(
    sl<GetGradingConfig>(),
    sl<SetupGrading>(),
    sl<UpdateGradingConfig>(),
  );
});

final gradeItemsProvider = StateNotifierProvider<GradeItemsNotifier, GradeItemsState>((ref) {
  return GradeItemsNotifier(
    sl<GetGradeItems>(),
    sl<CreateGradeItem>(),
    sl<DeleteGradeItem>(),
  );
});

final gradeScoresProvider = StateNotifierProvider<GradeScoresNotifier, GradeScoresState>((ref) {
  return GradeScoresNotifier(
    sl<GetScoresByItem>(),
    sl<SaveScores>(),
    sl<SetScoreOverride>(),
    sl<ClearScoreOverride>(),
  );
});

final quarterlyGradesProvider = StateNotifierProvider<QuarterlyGradesNotifier, QuarterlyGradesState>((ref) {
  return QuarterlyGradesNotifier(
    sl<GetQuarterlyGrades>(),
    sl<ComputeGrades>(),
    sl<GetGradeSummary>(),
    sl<UpdateQuarterlyGrade>(),
  );
});
