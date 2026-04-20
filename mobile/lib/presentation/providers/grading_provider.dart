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
  final GenerateScores _generateScores;

  GradeItemsNotifier(
    this._getGradeItems,
    this._createGradeItem,
    this._deleteGradeItem,
    this._generateScores,
  ) : super(GradeItemsState());

  Future<void> loadItems(String classId) async {
    print('*** GRADE PROVIDER: loadItems() - starting for classId: $classId, quarter: ${state.currentQuarter}, component: ${state.currentComponent}');
    ProviderLogger.instance.log('loadItems() - starting for classId: $classId, quarter: ${state.currentQuarter}, component: ${state.currentComponent}');
    state = state.copyWith(isLoading: true, error: null);
    print('*** GRADE PROVIDER: state set to loading');
    final result = await _getGradeItems(GetGradeItemsParams(
      classId: classId,
      gradingPeriodNumber: state.currentQuarter,
      component: state.currentComponent.isEmpty ? null : state.currentComponent,
    ));
    print('*** GRADE PROVIDER: _getGradeItems completed');
    result.fold(
      (failure) {
        print('*** GRADE PROVIDER: loadItems failed: ${AppErrorMapper.fromFailure(failure)}');
        ProviderLogger.instance.error('loadItems() - failed: ${AppErrorMapper.fromFailure(failure)}');
        state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure));
      },
      (items) {
        print('*** GRADE PROVIDER: loadItems success: loaded ${items.length} items');
        ProviderLogger.instance.log('loadItems() - success: loaded ${items.length} items');
        for (final item in items) {
          print('*** GRADE PROVIDER: item: ${item.title} (${item.component}) - totalPoints=${item.totalPoints} - source: ${item.sourceType}, sourceId: ${item.sourceId}');
          ProviderLogger.instance.log('loadItems() - item: ${item.title} (${item.component}) - totalPoints=${item.totalPoints} - source: ${item.sourceType}, sourceId: ${item.sourceId}');
        }
        state = state.copyWith(isLoading: false, items: items);
        print('*** GRADE PROVIDER: state updated with ${state.items.length} items');
        ProviderLogger.instance.log('loadItems() - state updated with ${state.items.length} items');
      },
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

  Future<void> backfillFromActivities(String classId, int gradingPeriodNumber) async {
    print('*** DEBUG: backfillFromActivities called with classId: $classId, quarter: $gradingPeriodNumber');
    print('*** GRADE PROVIDER: backfillFromActivities() - starting for classId: $classId, quarter: $gradingPeriodNumber');
    ProviderLogger.instance.log('backfillFromActivities() - starting for classId: $classId, quarter: $gradingPeriodNumber');
    print('*** GRADE PROVIDER: current state has ${state.items.length} items');
    ProviderLogger.instance.log('backfillFromActivities() - current state has ${state.items.length} items');
    
    print('*** DEBUG: existing grade items count: ${state.items.length}');
    for (final item in state.items) {
      print('*** DEBUG: existing grade item: ${item.title} (${item.component}) - source: ${item.sourceType}, sourceId: ${item.sourceId}');
    }
    
    final existingSourceIds = state.items
        .where((i) => i.sourceId != null)
        .map((i) => i.sourceId!)
        .toSet();
    
    print('*** GRADE PROVIDER: existing source IDs: $existingSourceIds');
    ProviderLogger.instance.log('backfillFromActivities() - existing source IDs: $existingSourceIds');

    final List<GradeItem> newItems = [];

    // Process assessments — forceRemote ensures we get fresh data even on cold cache
    print('*** GRADE PROVIDER: fetching assessments for backfill (forceRemote)');
    ProviderLogger.instance.log('backfillFromActivities() - fetching assessments (forceRemote)');

    final assessmentResult = await sl<GetAssessments>()(classId, forceRemote: true);
    await assessmentResult.fold(
      (failure) {
        print('*** GRADE PROVIDER: Failed to get assessments for backfill: $failure');
        ProviderLogger.instance.error('Failed to get assessments for backfill', failure);
      },
      (assessments) async {
        print('*** DEBUG: got ${assessments.length} assessments for backfill');
        print('*** GRADE PROVIDER: got ${assessments.length} assessments for backfill');
        ProviderLogger.instance.log('backfillFromActivities() - got ${assessments.length} assessments');
        for (final a in assessments) {
          print('*** DEBUG: assessment details - title: ${a.title}, component: ${a.component}, quarter: ${a.gradingPeriodNumber}, id: ${a.id}');
          print('*** DEBUG: checking conditions - targetQuarter: $gradingPeriodNumber, assessmentQuarter: ${a.gradingPeriodNumber}');
          print('*** DEBUG: checking conditions - componentNotNull: ${a.component != null}, existingSourceIdsContains: ${existingSourceIds.contains(a.id)}');
          print('*** GRADE PROVIDER: checking assessment: ${a.title} (${a.component}) - quarter: ${a.gradingPeriodNumber}, id: ${a.id}');
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
              print('*** GRADE PROVIDER: linking manual item "${manualMatch.title}" to assessment ${a.id}, fixing totalPoints ${manualMatch.totalPoints} -> ${a.totalPoints}');
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
                    print('*** GRADE PROVIDER: Failed to link manual item: ${a.title} - $failure');
                    ProviderLogger.instance.error('Failed to link manual item: ${a.title}', failure);
                  },
                  (_) {
                    print('*** GRADE PROVIDER: Linked manual item "${manualMatch.title}" to assessment ${a.id}');
                    ProviderLogger.instance.log('Linked manual item to assessment: ${a.title}');
                  },
                );
              } catch (e) {
                print('*** GRADE PROVIDER: Exception linking manual item: ${a.title} - $e');
                ProviderLogger.instance.error('Exception linking manual item: ${a.title}', e);
              }
            } else {
              print('*** GRADE PROVIDER: assessment qualifies for backfill, creating grade item');
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
                    print('*** GRADE PROVIDER: Failed to create grade item from assessment: ${a.title} - $failure');
                    ProviderLogger.instance.error('Failed to create grade item from assessment: ${a.title}', failure);
                  },
                  (item) {
                    print('*** GRADE PROVIDER: Created grade item from assessment: ${a.title} with ID: ${item.id}');
                    newItems.add(item);
                    ProviderLogger.instance.log('Created grade item from assessment: ${a.title} with ID: ${item.id}');
                  },
                );
              } catch (e) {
                print('*** GRADE PROVIDER: Exception creating grade item from assessment: ${a.title} - $e');
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
              print('*** BACKFILL UPDATE CHECK: ${a.title} | assessment.totalPoints=${a.totalPoints} | existingItem.totalPoints=${existingItem?.totalPoints} | needsUpdate=${existingItem != null && existingItem.totalPoints != a.totalPoints.toDouble()}');
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
            print('*** DEBUG: assessment ${a.title} does not qualify: $reason');
            print('*** GRADE PROVIDER: assessment ${a.title} does not qualify: $reason');
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
    print('*** GRADE PROVIDER: backfill processing complete, new items count: ${newItems.length}');
    ProviderLogger.instance.log('backfillFromActivities() - processing complete, new items count: ${newItems.length}');
    if (newItems.isNotEmpty) {
      print('*** GRADE PROVIDER: updating state with ${newItems.length} new items');
      ProviderLogger.instance.log('backfillFromActivities() - updating state with ${newItems.length} new items');
      state = state.copyWith(items: [...state.items, ...newItems]);
      print('*** GRADE PROVIDER: Backfill completed: added ${newItems.length} grade items, total items now: ${state.items.length}');
      ProviderLogger.instance.log('Backfill completed: added ${newItems.length} grade items, total items now: ${state.items.length}');
    } else {
      print('*** GRADE PROVIDER: Backfill completed: no new items to add, total items remain: ${state.items.length}');
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
    print('*** GRADE PROVIDER: generateScoresForItems() - starting for classId: $classId, quarter: ${state.currentQuarter}');
    ProviderLogger.instance.log('generateScoresForItems() - starting for classId: $classId, quarter: ${state.currentQuarter}');
    
    final result = await _generateScores.generateScoresForClass(GenerateScoresParams(
      classId: classId,
      gradingPeriodNumber: state.currentQuarter,
    ));
    
    result.fold(
      (failure) {
        print('*** GRADE PROVIDER: generateScoresForItems failed: ${AppErrorMapper.fromFailure(failure)}');
        ProviderLogger.instance.error('generateScoresForItems() - failed: ${AppErrorMapper.fromFailure(failure)}');
      },
      (_) {
        print('*** GRADE PROVIDER: generateScoresForItems completed successfully');
        ProviderLogger.instance.log('generateScoresForItems() - completed successfully');
      },
    );
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
    state = state.copyWith(error: null, successMessage: null);
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
    // Optimistically update the in-memory map so the cell shows the new value
    // immediately. The save is sync-queued and will reach the server later;
    // re-fetching from remote right now would return the stale (pre-save) value.
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
    final result = await _updatePeriodGrade(
      classId: classId,
      studentId: studentId,
      gradingPeriodNumber: quarter,
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
              return {...row, 'transmuted_grade': transmutedGrade.toDouble()};
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
