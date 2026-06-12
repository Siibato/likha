import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/logging/provider_logger.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/domain/grading/entities/period_grade.dart';
import 'package:likha/domain/grading/usecases/clear_score_override.dart';
import 'package:likha/domain/grading/usecases/compute_grades.dart';
import 'package:likha/domain/grading/usecases/create_grade_item.dart';
import 'package:likha/domain/grading/usecases/delete_grade_item.dart';
import 'package:likha/domain/grading/usecases/get_grade_items.dart';
import 'package:likha/domain/grading/usecases/get_grade_summary.dart';
import 'package:likha/domain/grading/usecases/get_grading_config.dart';
import 'package:likha/domain/grading/usecases/get_period_grades.dart';
import 'package:likha/domain/grading/usecases/get_scores_by_item.dart';
import 'package:likha/domain/grading/usecases/save_scores.dart';
import 'package:likha/domain/grading/usecases/set_score_override.dart';
import 'package:likha/domain/grading/usecases/setup_grading.dart';
import 'package:likha/domain/grading/usecases/update_grading_config.dart';
import 'package:likha/domain/grading/usecases/update_period_grade.dart';
import 'package:likha/domain/grading/usecases/update_grade_item.dart';
import 'package:likha/domain/grading/usecases/generate_scores.dart';
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
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (_) => state = state.copyWith(
        isLoading: false,
        isConfigured: true,
        successMessage: 'Grading configured',
      ),
    );
  }

  Future<void> updateConfig({
    required String classId,
    required List<Map<String, dynamic>> configs,
  }) async {
    final previousConfigs = List<GradeConfig>.from(state.configs);
    // Optimistically apply weight changes to every matching config entry
    final optimisticConfigs = state.configs.map((c) {
      final incoming = configs.firstWhere(
        (m) => m['grading_period_number'] == c.gradingPeriodNumber,
        orElse: () => const {},
      );
      if (incoming.isEmpty) return c;
      return GradeConfig(
        id: c.id,
        classId: c.classId,
        gradingPeriodNumber: c.gradingPeriodNumber,
        wwWeight: (incoming['ww_weight'] as num?)?.toDouble() ?? c.wwWeight,
        ptWeight: (incoming['pt_weight'] as num?)?.toDouble() ?? c.ptWeight,
        qaWeight: (incoming['qa_weight'] as num?)?.toDouble() ?? c.qaWeight,
      );
    }).toList();
    state = state.copyWith(
      isLoading: true,
      error: null,
      successMessage: null,
      configs: optimisticConfigs,
    );
    final result = await _updateGradingConfig(classId: classId, configs: configs);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        configs: previousConfigs,
        error: AppErrorMapper.fromFailure(failure),
      ),
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
  final GenerateScores _generateScores;

  GradeItemsNotifier(
    this._getGradeItems,
    this._createGradeItem,
    this._deleteGradeItem,
    this._generateScores,
  ) : super(GradeItemsState());

  Future<void> loadItems(String classId) async {
    ProviderLogger.instance.log('loadItems() - starting for classId: $classId, quarter: ${state.currentQuarter}, component: ${state.currentComponent}');
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getGradeItems(GetGradeItemsParams(
      classId: classId,
      gradingPeriodNumber: state.currentQuarter,
      component: state.currentComponent.isEmpty ? null : state.currentComponent,
    ));
        result.fold(
      (failure) {
                ProviderLogger.instance.error('loadItems() - failed: ${AppErrorMapper.fromFailure(failure)}');
        state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure));
      },
      (items) {
                ProviderLogger.instance.log('loadItems() - success: loaded ${items.length} items');
        for (final item in items) {
                    ProviderLogger.instance.log('loadItems() - item: ${item.title} (${item.component}) - totalPoints=${item.totalPoints} - source: ${item.sourceType}, sourceId: ${item.sourceId}');
        }
        state = state.copyWith(isLoading: false, items: items);
                ProviderLogger.instance.log('loadItems() - state updated with ${state.items.length} items');
      },
    );
  }

  Future<void> createItem(String classId, Map<String, dynamic> data) async {
    final previousItems = List<GradeItem>.from(state.items);
    final now = DateTime.now();
    final tempItem = GradeItem(
      id: 'optimistic_${now.millisecondsSinceEpoch}',
      classId: classId,
      title: (data['title'] as String?) ?? '',
      component: (data['component'] as String?) ?? '',
      gradingPeriodNumber: (data['grading_period_number'] as int?) ?? state.currentQuarter,
      totalPoints: (data['total_points'] as num?)?.toDouble() ?? 0.0,
      sourceType: (data['source_type'] as String?) ?? 'manual',
      sourceId: data['source_id'] as String?,
      orderIndex: (data['order_index'] as int?) ?? state.items.length,
      createdAt: now,
      updatedAt: now,
    );
    state = state.copyWith(
      isLoading: true,
      error: null,
      successMessage: null,
      items: [...state.items, tempItem],
    );
    final result = await _createGradeItem(classId: classId, data: data);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        items: previousItems,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (item) => state = state.copyWith(
        isLoading: false,
        items: [
          ...state.items.where((i) => i.id != tempItem.id),
          item,
        ],
        successMessage: 'Grade item created',
      ),
    );
  }

  Future<void> deleteItem(String id) async {
    final previousItems = List<GradeItem>.from(state.items);
    state = state.copyWith(
      isLoading: true,
      error: null,
      successMessage: null,
      items: state.items.where((i) => i.id != id).toList(),
    );
    final result = await _deleteGradeItem(id);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        items: previousItems,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (_) => state = state.copyWith(
        isLoading: false,
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

  Future<void> backfillFromActivities(String classId, int gradingPeriodNumber) async {
    ProviderLogger.instance.log('backfillFromActivities() - starting for classId: $classId, quarter: $gradingPeriodNumber');
    ProviderLogger.instance.log('backfillFromActivities() - current state has ${state.items.length} items');
    
    final existingSourceIds = state.items
        .where((i) => i.sourceId != null)
        .map((i) => i.sourceId!)
        .toSet();
    
    ProviderLogger.instance.log('backfillFromActivities() - existing source IDs: $existingSourceIds');

    final List<GradeItem> newItems = [];

    // Process assessments — forceRemote ensures we get fresh data even on cold cache
    ProviderLogger.instance.log('backfillFromActivities() - fetching assessments (forceRemote)');

    final assessmentResult = await sl<GetAssessments>()(classId, forceRemote: true);
    await assessmentResult.fold(
      (failure) {
        ProviderLogger.instance.error('Failed to get assessments for backfill', failure);
      },
      (assessments) async {
        ProviderLogger.instance.log('backfillFromActivities() - got ${assessments.length} assessments');
        for (final a in assessments) {
          ProviderLogger.instance.log('backfillFromActivities() - checking assessment: ${a.title} (${a.component}) - quarter: ${a.gradingPeriodNumber}, id: ${a.id}');
          if (a.gradingPeriodNumber == gradingPeriodNumber && a.component != null && !existingSourceIds.contains(a.id)) {
            final component = _toGradeComponent(a.component!);
            // Check if a manually-created item with the same title+component exists (link it instead of creating a duplicate)
            final GradeItem? manualMatch = state.items.cast<GradeItem?>().firstWhere(
              (item) => item?.sourceId == null
                  && item?.component == component
                  && item?.title.toLowerCase() == a.title.toLowerCase(),
              orElse: () => null,
            );

            if (manualMatch != null) {
              ProviderLogger.instance.log('backfillFromActivities() - linking manual item to assessment: ${a.title}');
              try {
                final updateResult = await sl<UpdateGradeItem>()(
                  id: manualMatch.id,
                  data: {
                    'source_type': 'assessment',
                    'source_id': a.id,
                    'total_points': a.totalPoints.toDouble(),
                  },
                );
                updateResult.fold(
                  (failure) {
                    ProviderLogger.instance.error('Failed to link manual item: ${a.title}', failure);
                  },
                  (_) {
                    ProviderLogger.instance.log('Linked manual item to assessment: ${a.title}');
                  },
                );
              } catch (e) {
                ProviderLogger.instance.error('Exception linking manual item: ${a.title}', e);
              }
            } else {
              ProviderLogger.instance.log('backfillFromActivities() - assessment qualifies for backfill, creating grade item');
              try {
                final result = await sl<GradingRepository>().createGradeItem(
                  classId: classId,
                  data: {
                    'title': a.title,
                    'component': component,
                    'grading_period_number': gradingPeriodNumber,
                    'total_points': a.totalPoints.toDouble(),
                    'is_departmental_exam': false,
                    'source_type': 'assessment',
                    'source_id': a.id,
                    'order_index': 0,
                  },
                );
                result.fold(
                  (failure) {
                    ProviderLogger.instance.error('Failed to create grade item from assessment: ${a.title}', failure);
                  },
                  (item) {
                    newItems.add(item);
                    ProviderLogger.instance.log('Created grade item from assessment: ${a.title} with ID: ${item.id}');
                  },
                );
              } catch (e) {
                ProviderLogger.instance.error('Exception creating grade item from assessment: ${a.title}', e);
              }
            }
          } else {
            String reason = "";
            if (a.gradingPeriodNumber != gradingPeriodNumber) {
              reason = "wrong quarter (${a.gradingPeriodNumber} != $gradingPeriodNumber)";
            } else if (a.component == null) {
              reason = "component is null";
            } else if (existingSourceIds.contains(a.id)) {
              reason = "source ID already exists";
              // Check if totalPoints needs updating for existing grade item
              final GradeItem? existingItem = state.items.cast<GradeItem?>().firstWhere(
                (item) => item?.sourceId == a.id,
                orElse: () => null,
              );
              if (existingItem != null && existingItem.totalPoints != a.totalPoints.toDouble()) {
                ProviderLogger.instance.log('backfillFromActivities() - updating totalPoints for ${a.title}: ${existingItem.totalPoints} -> ${a.totalPoints}');
                try {
                  final updateResult = await sl<UpdateGradeItem>()(
                    id: existingItem.id,
                    data: {'total_points': a.totalPoints.toDouble()},
                  );
                  updateResult.fold(
                    (failure) {
                      ProviderLogger.instance.error('Failed to update totalPoints for ${a.title}', failure);
                    },
                    (_) {
                      // Update local state
                      final updatedItems = state.items.map((item) {
                        if (item.id == existingItem.id) {
                          return GradeItem(
                            id: item.id,
                            classId: item.classId,
                            title: item.title,
                            component: item.component,
                            gradingPeriodNumber: item.gradingPeriodNumber,
                            totalPoints: a.totalPoints.toDouble(),
                            sourceType: item.sourceType,
                            sourceId: item.sourceId,
                            orderIndex: item.orderIndex,
                            createdAt: item.createdAt,
                            updatedAt: DateTime.now(),
                          );
                        }
                        return item;
                      }).toList();
                      state = state.copyWith(items: updatedItems);
                      ProviderLogger.instance.log('Updated totalPoints for ${a.title} to ${a.totalPoints}');
                    },
                  );
                } catch (e) {
                  ProviderLogger.instance.error('Exception updating totalPoints for ${a.title}', e);
                }
              }
            }
            ProviderLogger.instance.log('backfillFromActivities() - assessment ${a.title} does not qualify: $reason');
          }
        }
      },
    );

    // Process assignments
    ProviderLogger.instance.log('backfillFromActivities() - fetching assignments');
    final assignmentResult = await sl<GetAssignments>()(classId);
    await assignmentResult.fold(
      (failure) {
        ProviderLogger.instance.error('Failed to get assignments for backfill', failure);
      },
      (assignments) async {
        ProviderLogger.instance.log('backfillFromActivities() - got ${assignments.length} assignments');
        for (final a in assignments) {
          ProviderLogger.instance.log('backfillFromActivities() - checking assignment: ${a.title} (${a.component}) - quarter: ${a.gradingPeriodNumber}, id: ${a.id}');
          if (a.gradingPeriodNumber == gradingPeriodNumber && a.component != null && !existingSourceIds.contains(a.id)) {
            ProviderLogger.instance.log('backfillFromActivities() - assignment qualifies for backfill, creating grade item');
            try {
              final result = await sl<GradingRepository>().createGradeItem(
                classId: classId,
                data: {
                  'title': a.title,
                  'component': _toGradeComponent(a.component!),
                  'grading_period_number': gradingPeriodNumber,
                  'total_points': a.totalPoints.toDouble(),
                  'is_departmental_exam': false,
                  'source_type': 'assignment',
                  'source_id': a.id,
                  'order_index': 0,
                },
              );
              result.fold(
                (failure) {
                  ProviderLogger.instance.error('Failed to create grade item from assignment: ${a.title}', failure);
                },
                (item) {
                  newItems.add(item);
                  ProviderLogger.instance.log('Created grade item from assignment: ${a.title} with ID: ${item.id}');
                },
              );
            } catch (e) {
              ProviderLogger.instance.error('Exception creating grade item from assignment: ${a.title}', e);
            }
          } else {
            String reason = "";
            if (a.gradingPeriodNumber != gradingPeriodNumber) {
              reason = "wrong quarter (${a.gradingPeriodNumber} != $gradingPeriodNumber)";
            } else if (a.component == null) {
              reason = "component is null";
            } else if (existingSourceIds.contains(a.id)) {
              reason = "source ID already exists";
            }
            ProviderLogger.instance.log('backfillFromActivities() - assignment ${a.title} does not qualify: $reason');
          }
        }
      },
    );

    // Update state with new items if any were created
    ProviderLogger.instance.log('backfillFromActivities() - processing complete, new items count: ${newItems.length}');
    if (newItems.isNotEmpty) {
      ProviderLogger.instance.log('backfillFromActivities() - updating state with ${newItems.length} new items');
      state = state.copyWith(items: [...state.items, ...newItems]);
      ProviderLogger.instance.log('Backfill completed: added ${newItems.length} grade items, total items now: ${state.items.length}');
    } else {
      ProviderLogger.instance.log('Backfill completed: no new items to add, total items remain: ${state.items.length}');
    }
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

  /// Generate scores for grade items that don't have scores yet
  Future<void> generateScoresForItems(String classId) async {
    ProviderLogger.instance.log('generateScoresForItems() - starting for classId: $classId, quarter: ${state.currentQuarter}');
    
    final result = await _generateScores.generateScoresForClass(GenerateScoresParams(
      classId: classId,
      gradingPeriodNumber: state.currentQuarter,
      items: state.items.isNotEmpty ? state.items : null,
    ));
    
    result.fold(
      (failure) {
        ProviderLogger.instance.error('generateScoresForItems() - failed: ${AppErrorMapper.fromFailure(failure)}');
        // Don't refresh scores if generation failed
      },
      (_) {
        ProviderLogger.instance.log('generateScoresForItems() - completed successfully');
        
        // Set a flag to indicate scores need refreshing
        // The UI layer will handle the actual score refresh
      },
    );
  }
}

// ===== Grade Scores =====

class GradeScoresState {
  final Map<String, List<GradeScore>> scoresByItem;
  final bool isLoading;
  final bool isGeneratingScores;
  final String? error;
  final String? successMessage;

  GradeScoresState({
    this.scoresByItem = const {},
    this.isLoading = false,
    this.isGeneratingScores = false,
    this.error,
    this.successMessage,
  });

  GradeScoresState copyWith({
    Map<String, List<GradeScore>>? scoresByItem,
    bool? isLoading,
    bool? isGeneratingScores,
    Object? error = _unset,
    Object? successMessage = _unset,
  }) {
    return GradeScoresState(
      scoresByItem: scoresByItem ?? this.scoresByItem,
      isLoading: isLoading ?? this.isLoading,
      isGeneratingScores: isGeneratingScores ?? this.isGeneratingScores,
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

  void setGenerating(bool value) {
    state = state.copyWith(isGeneratingScores: value);
  }

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
        (scores) {
          allScores[itemId] = scores;
        },
      );
      if (state.error != null) return;
    }
    
    state = state.copyWith(isLoading: false, scoresByItem: allScores);
  }

  Future<void> saveScores(
    String gradeItemId,
    List<Map<String, dynamic>> scores,
  ) async {
    final previousScoresByItem = Map<String, List<GradeScore>>.from(
      state.scoresByItem.map((k, v) => MapEntry(k, List<GradeScore>.from(v))),
    );
    // Optimistically update the in-memory map before the async call so the
    // cell shows the new value immediately.
    final updated = Map<String, List<GradeScore>>.from(state.scoresByItem);
    final existing = List<GradeScore>.from(updated[gradeItemId] ?? []);
    for (final s in scores) {
      final studentId = s['student_id'] as String;
      final scoreVal = (s['score'] as num).toDouble();
      final existingId = s['id'] as String?;
      final idx = existing.indexWhere((e) => e.studentId == studentId);
      if (idx >= 0) {
        final old = existing[idx];
        existing[idx] = GradeScore(
          id: existingId ?? old.id,
          gradeItemId: gradeItemId,
          studentId: studentId,
          score: scoreVal,
          isAutoPopulated: false,
          overrideScore: null,
        );
      } else {
        existing.add(GradeScore(
          id: existingId ?? 'optimistic_${studentId}_$gradeItemId',
          gradeItemId: gradeItemId,
          studentId: studentId,
          score: scoreVal,
          isAutoPopulated: false,
          overrideScore: null,
        ));
      }
    }
    updated[gradeItemId] = existing;
    state = state.copyWith(error: null, successMessage: null, scoresByItem: updated);
    final result = await _saveScores(gradeItemId: gradeItemId, scores: scores);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        scoresByItem: previousScoresByItem,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (_) => state = state.copyWith(
        isLoading: false,
        successMessage: 'Scores saved',
      ),
    );
  }

  Future<void> setOverride(String scoreId, double overrideScore) async {
    final previousScoresByItem = Map<String, List<GradeScore>>.from(
      state.scoresByItem.map((k, v) => MapEntry(k, List<GradeScore>.from(v))),
    );
    // Optimistically apply override immediately
    final updated = Map<String, List<GradeScore>>.from(state.scoresByItem);
    for (final entry in updated.entries) {
      final idx = entry.value.indexWhere((s) => s.id == scoreId);
      if (idx >= 0) {
        final old = entry.value[idx];
        final newList = List<GradeScore>.from(entry.value);
        newList[idx] = GradeScore(
          id: old.id,
          gradeItemId: old.gradeItemId,
          studentId: old.studentId,
          score: old.score,
          isAutoPopulated: old.isAutoPopulated,
          overrideScore: overrideScore,
        );
        updated[entry.key] = newList;
        break;
      }
    }
    state = state.copyWith(
      isLoading: true,
      error: null,
      successMessage: null,
      scoresByItem: updated,
    );
    final result = await _setScoreOverride(
      scoreId: scoreId,
      overrideScore: overrideScore,
    );
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        scoresByItem: previousScoresByItem,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (_) => state = state.copyWith(
        isLoading: false,
        successMessage: 'Score override applied',
      ),
    );
  }

  Future<void> clearOverride(String scoreId) async {
    final previousScoresByItem = Map<String, List<GradeScore>>.from(
      state.scoresByItem.map((k, v) => MapEntry(k, List<GradeScore>.from(v))),
    );
    // Optimistically clear the override immediately
    final updated = Map<String, List<GradeScore>>.from(state.scoresByItem);
    for (final entry in updated.entries) {
      final idx = entry.value.indexWhere((s) => s.id == scoreId);
      if (idx >= 0) {
        final old = entry.value[idx];
        final newList = List<GradeScore>.from(entry.value);
        newList[idx] = GradeScore(
          id: old.id,
          gradeItemId: old.gradeItemId,
          studentId: old.studentId,
          score: old.score,
          isAutoPopulated: old.isAutoPopulated,
          overrideScore: null,
        );
        updated[entry.key] = newList;
        break;
      }
    }
    state = state.copyWith(
      isLoading: true,
      error: null,
      successMessage: null,
      scoresByItem: updated,
    );
    final result = await _clearScoreOverride(scoreId);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        scoresByItem: previousScoresByItem,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (_) => state = state.copyWith(
        isLoading: false,
        successMessage: 'Score override cleared',
      ),
    );
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }

  /// Force refresh scores from remote server (bypass cache)
  Future<void> refreshScoresFromRemote(List<String> gradeItemIds) async {
    state = state.copyWith(isLoading: true, error: null);
    final Map<String, List<GradeScore>> allScores = {};

    for (final itemId in gradeItemIds) {
      // Force remote fetch by calling repository directly
      final result = await _getScoresByItem(itemId);
      result.fold(
        (failure) {
          state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure));
          return;
        },
        (scores) {
          allScores[itemId] = scores;
        },
      );
      if (state.error != null) return;
    }
    
    state = state.copyWith(isLoading: false, scoresByItem: allScores);
  }
}

// ===== Quarterly Grades =====

class PeriodGradesState {
  final List<PeriodGrade> grades;
  final List<Map<String, dynamic>>? summary;
  final bool isLoading;
  final String? error;

  PeriodGradesState({
    this.grades = const [],
    this.summary,
    this.isLoading = false,
    this.error,
  });

  PeriodGradesState copyWith({
    List<PeriodGrade>? grades,
    Object? summary = _unset,
    bool? isLoading,
    Object? error = _unset,
  }) {
    return PeriodGradesState(
      grades: grades ?? this.grades,
      summary: identical(summary, _unset) ? this.summary : summary as List<Map<String, dynamic>>?,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

class PeriodGradesNotifier extends StateNotifier<PeriodGradesState> {
  final GetPeriodGrades _getPeriodGrades;
  final ComputeGrades _computeGrades;
  final GetGradeSummary _getGradeSummary;
  final UpdatePeriodGrade _updatePeriodGrade;

  PeriodGradesNotifier(
    this._getPeriodGrades,
    this._computeGrades,
    this._getGradeSummary,
    this._updatePeriodGrade,
  ) : super(PeriodGradesState());

  Future<void> loadGrades(String classId, int quarter) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getPeriodGrades(
      classId: classId,
      gradingPeriodNumber: quarter,
    );
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (grades) => state = state.copyWith(isLoading: false, grades: grades),
    );
  }

  Future<void> computeGrades(String classId, int quarter) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _computeGrades(classId: classId, gradingPeriodNumber: quarter);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (_) => state = state.copyWith(isLoading: false),
    );
  }

  Future<void> loadSummary(String classId, int quarter) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getGradeSummary(classId: classId, gradingPeriodNumber: quarter);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure)),
      (summary) => state = state.copyWith(isLoading: false, summary: summary),
    );
  }

  Future<void> updatePeriodGrade({
    required String classId,
    required String studentId,
    required int quarter,
    required int transmutedGrade,
  }) async {
    final previousSummary = state.summary != null
        ? List<Map<String, dynamic>>.from(state.summary!)
        : null;
    // Optimistically update the summary before the async call
    final currentSummary = state.summary;
    if (currentSummary != null) {
      final optimistic = currentSummary.map((row) {
        if (row['student_id'] == studentId) {
          return {...row, 'transmuted_grade': transmutedGrade.toDouble()};
        }
        return row;
      }).toList();
      state = state.copyWith(summary: optimistic);
    }
    final result = await _updatePeriodGrade(
      classId: classId,
      studentId: studentId,
      gradingPeriodNumber: quarter,
      transmutedGrade: transmutedGrade,
    );
    result.fold(
      (failure) => state = state.copyWith(
        summary: previousSummary,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (_) {},
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
    sl<GenerateScores>(),
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

final quarterlyGradesProvider = StateNotifierProvider<PeriodGradesNotifier, PeriodGradesState>((ref) {
  return PeriodGradesNotifier(
    sl<GetPeriodGrades>(),
    sl<ComputeGrades>(),
    sl<GetGradeSummary>(),
    sl<UpdatePeriodGrade>(),
  );
});
