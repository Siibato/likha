import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/logging/provider_logger.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/usecases/create_grade_item.dart';
import 'package:likha/domain/grading/usecases/delete_grade_item.dart';
import 'package:likha/domain/grading/usecases/generate_scores.dart';
import 'package:likha/domain/grading/usecases/get_grade_items.dart';
import 'package:likha/domain/grading/usecases/update_grade_item.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';
import 'package:likha/domain/assessments/usecases/get_assessments.dart';
import 'package:likha/domain/assignments/usecases/get_assignments.dart';
import 'package:likha/injection_container.dart';

const _unset = Object();

class GradeItemsState {
  final List<GradeItem> items;
  final int currentTerm;
  final String currentComponent;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  GradeItemsState({
    this.items = const [],
    this.currentTerm = 1,
    this.currentComponent = '',
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  GradeItemsState copyWith({
    List<GradeItem>? items,
    int? currentTerm,
    String? currentComponent,
    bool? isLoading,
    Object? error = _unset,
    Object? successMessage = _unset,
  }) {
    return GradeItemsState(
      items: items ?? this.items,
      currentTerm: currentTerm ?? this.currentTerm,
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
    ProviderLogger.instance.log('loadItems() - starting for classId: $classId, term: ${state.currentTerm}, component: ${state.currentComponent}');
    state = state.copyWith(isLoading: state.items.isEmpty, error: null);
    final result = await _getGradeItems(GetGradeItemsParams(
      classId: classId,
      termNumber: state.currentTerm,
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
    state = state.copyWith(error: null, successMessage: null);
    final result = await _createGradeItem(classId: classId, data: data);
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
      ),
      (mutationResult) => state = state.copyWith(
        successMessage: 'Grade item created',
      ),
    );
  }

  Future<void> deleteItem(String id) async {
    state = state.copyWith(error: null, successMessage: null);
    final result = await _deleteGradeItem(id);
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
      ),
      (_) => state = state.copyWith(
        successMessage: 'Grade item deleted',
      ),
    );
  }

  String _toGradeComponent(String c) {
    switch (c) {
      case 'written_work': return 'ww';
      case 'performance_task': return 'pt';
      case 'term_assessment': return 'qa';
      default: return c;
    }
  }

  Future<void> backfillFromActivities(String classId, int termNumber) async {
    ProviderLogger.instance.log('backfillFromActivities() - starting for classId: $classId, term: $termNumber');
    ProviderLogger.instance.log('backfillFromActivities() - current state has ${state.items.length} items');

    final existingSourceIds = state.items
        .where((i) => i.sourceId != null)
        .map((i) => i.sourceId!)
        .toSet();

    ProviderLogger.instance.log('backfillFromActivities() - existing source IDs: $existingSourceIds');

    // Process assessments — fetch fresh data for backfill
    ProviderLogger.instance.log('backfillFromActivities() - fetching assessments');

    final assessmentResult = await sl<GetAssessments>()(classId);
    await assessmentResult.fold(
      (failure) {
        ProviderLogger.instance.error('Failed to get assessments for backfill', failure);
      },
      (assessments) async {
        ProviderLogger.instance.log('backfillFromActivities() - got ${assessments.length} assessments');
        for (final a in assessments) {
          ProviderLogger.instance.log('backfillFromActivities() - checking assessment: ${a.title} (${a.component}) - term: ${a.termNumber}, id: ${a.id}');
          if (a.termNumber == termNumber && a.component != null && !existingSourceIds.contains(a.id)) {
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
                    'term_number': termNumber,
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
                  (mutationResult) {
                    ProviderLogger.instance.log('Created grade item from assessment: ${a.title} with ID: ${mutationResult.entity.id}');
                  },
                );
              } catch (e) {
                ProviderLogger.instance.error('Exception creating grade item from assessment: ${a.title}', e);
              }
            }
          } else {
            String reason = "";
            if (a.termNumber != termNumber) {
              reason = "wrong term (${a.termNumber} != $termNumber)";
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
          ProviderLogger.instance.log('backfillFromActivities() - checking assignment: ${a.title} (${a.component}) - term: ${a.termNumber}, id: ${a.id}');
          if (a.termNumber == termNumber && a.component != null && !existingSourceIds.contains(a.id)) {
            ProviderLogger.instance.log('backfillFromActivities() - assignment qualifies for backfill, creating grade item');
            try {
              final result = await sl<GradingRepository>().createGradeItem(
                classId: classId,
                data: {
                  'title': a.title,
                  'component': _toGradeComponent(a.component!),
                  'term_number': termNumber,
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
                (mutationResult) {
                  ProviderLogger.instance.log('Created grade item from assignment: ${a.title} with ID: ${mutationResult.entity.id}');
                },
              );
            } catch (e) {
              ProviderLogger.instance.error('Exception creating grade item from assignment: ${a.title}', e);
            }
          } else {
            String reason = "";
            if (a.termNumber != termNumber) {
              reason = "wrong term (${a.termNumber} != $termNumber)";
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

    ProviderLogger.instance.log('Backfill completed');
  }

  void setTerm(int term) {
    state = state.copyWith(currentTerm: term);
  }

  void setComponent(String component) {
    state = state.copyWith(currentComponent: component);
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }

  /// Generate scores for grade items that don't have scores yet
  Future<void> generateScoresForItems(String classId) async {
    ProviderLogger.instance.log('generateScoresForItems() - starting for classId: $classId, term: ${state.currentTerm}');
    
    final result = await _generateScores.generateScoresForClass(GenerateScoresParams(
      classId: classId,
      termNumber: state.currentTerm,
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

final gradeItemsProvider = StateNotifierProvider<GradeItemsNotifier, GradeItemsState>((ref) {
  return GradeItemsNotifier(
    sl<GetGradeItems>(),
    sl<CreateGradeItem>(),
    sl<DeleteGradeItem>(),
    sl<GenerateScores>(),
  );
});
