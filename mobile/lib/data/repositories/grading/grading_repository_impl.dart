import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading_remote_datasource.dart';
import 'package:likha/data/models/grading/grade_config_model.dart';
import 'package:likha/data/models/grading/grade_item_model.dart';
import 'package:likha/data/models/grading/grade_score_model.dart';
import 'package:likha/data/models/grading/period_grade_model.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/domain/grading/entities/period_grade.dart';
import 'package:likha/domain/grading/entities/general_average.dart';
import 'package:likha/domain/grading/entities/sf9.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class GradingRepositoryImpl implements GradingRepository {
  final GradingRemoteDataSource _remoteDataSource;
  final GradingLocalDataSource _localDataSource;
  final ServerReachabilityService _serverReachabilityService;
  final SyncQueue _syncQueue;

  GradingRepositoryImpl({
    required GradingRemoteDataSource remoteDataSource,
    required GradingLocalDataSource localDataSource,
    required ServerReachabilityService serverReachabilityService,
    required SyncQueue syncQueue,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _serverReachabilityService = serverReachabilityService,
        _syncQueue = syncQueue;

  // ===== Helpers =====

  GradeConfig _configToEntity(GradeConfigModel m) => GradeConfig(
        id: m.id,
        classId: m.classId,
        gradingPeriodNumber: m.gradingPeriodNumber,
        wwWeight: m.wwWeight,
        ptWeight: m.ptWeight,
        qaWeight: m.qaWeight,
      );

  GradeItem _itemToEntity(GradeItemModel m) => GradeItem(
        id: m.id,
        classId: m.classId,
        title: m.title,
        component: m.component,
        gradingPeriodNumber: m.gradingPeriodNumber,
        totalPoints: m.totalPoints,
        sourceType: m.sourceType,
        sourceId: m.sourceId,
        orderIndex: m.orderIndex,
        createdAt: m.createdAt,
        updatedAt: m.updatedAt,
      );

  GradeScore _scoreToEntity(GradeScoreModel m) => GradeScore(
        id: m.id,
        gradeItemId: m.gradeItemId,
        studentId: m.studentId,
        score: m.score,
        isAutoPopulated: m.isAutoPopulated,
        overrideScore: m.overrideScore,
      );

  PeriodGrade _periodToEntity(PeriodGradeModel m) => PeriodGrade(
        id: m.id,
        classId: m.classId,
        studentId: m.studentId,
        gradingPeriodNumber: m.gradingPeriodNumber,
        initialGrade: m.initialGrade,
        transmutedGrade: m.transmutedGrade,
        isLocked: m.isLocked,
        computedAt: m.computedAt,
      );

  /// DepEd weight presets — mirrors class_grading_setup_page.dart
  static const _weightPresets = {
    'language': (ww: 30.0, pt: 50.0, qa: 20.0),
    'ap_esp': (ww: 30.0, pt: 50.0, qa: 20.0),
    'math_sci': (ww: 40.0, pt: 40.0, qa: 20.0),
    'mapeh_tle': (ww: 20.0, pt: 60.0, qa: 20.0),
    'shs_core': (ww: 25.0, pt: 50.0, qa: 25.0),
    'shs_academic': (ww: 25.0, pt: 45.0, qa: 30.0),
    'shs_tvl': (ww: 25.0, pt: 45.0, qa: 30.0),
    'shs_immersion': (ww: 35.0, pt: 40.0, qa: 25.0),
  };

  // ===== Config =====

  @override
  ResultFuture<List<GradeConfig>> getGradingConfig({
    required String classId,
  }) async {
    try {
      // Fetch from server when online so the UI always reflects server state.
      if (_serverReachabilityService.isServerReachable) {
        try {
          final models = await _remoteDataSource.getGradingConfig(classId: classId);
          if (models.isNotEmpty) {
            try { await _localDataSource.saveConfigs(models); } catch (_) {}
            return Right(models.map(_configToEntity).toList());
          }
          // Server returned empty — config may be pending sync; fall through to cache.
        } catch (_) {
          // Server fetch failed — fall through to cache.
        }
      }

      final cached = await _localDataSource.getConfigByClass(classId);
      if (cached.isNotEmpty) {
        return Right(cached.map(_configToEntity).toList());
      }

      // Cache empty AND server wasn't tried (isServerReachable was false).
      // This happens during cold open: the health-check ping hasn't resolved yet
      // so isServerReachable is still false even though the server is online.
      // Make one fallback attempt so we don't permanently show "not configured".
      if (!_serverReachabilityService.isServerReachable) {
        try {
          final models = await _remoteDataSource.getGradingConfig(classId: classId);
          if (models.isNotEmpty) {
            try { await _localDataSource.saveConfigs(models); } catch (_) {}
            return Right(models.map(_configToEntity).toList());
          }
        } catch (_) {
          // Genuinely offline — return empty list.
        }
      }

      return const Right([]);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultVoid setupGrading({
    required String classId,
    required String gradeLevel,
    required String subjectGroup,
    required String schoolYear,
    int? semester,
  }) async {
    try {
      // Save locally first (optimistic) — mirror server behaviour: Q1-Q4
      final weights = _weightPresets[subjectGroup];
      if (weights != null) {
        final now = DateTime.now().toIso8601String();
        final configs = [
          for (int q = 1; q <= 4; q++)
            GradeConfigModel(
              id: const Uuid().v4(),
              classId: classId,
              gradingPeriodNumber: q,
              wwWeight: weights.ww,
              ptWeight: weights.pt,
              qaWeight: weights.qa,
              createdAt: now,
              updatedAt: now,
            ),
        ];
        await _localDataSource.saveConfigs(configs);
      }

      // If online, attempt direct remote call first.
      // Only fall back to sync queue when the direct call fails so we avoid
      // sending a duplicate "setup" operation that would hit the server's
      // UNIQUE(class_id, quarter) constraint and be permanently marked failed.
      bool remoteSucceeded = false;
      if (_serverReachabilityService.isServerReachable) {
        try {
          await _remoteDataSource.setupGrading(
            classId: classId,
            data: {
              'grade_level': gradeLevel,
              'subject_group': subjectGroup,
              'school_year': schoolYear,
              if (semester != null) 'semester': semester,
            },
          );
          remoteSucceeded = true;
          // Next getGradingConfig call will fetch server-assigned IDs
          // automatically (server-first pattern).
        } catch (_) {
          // Direct call failed — sync queue will handle it below
        }
      }

      if (!remoteSucceeded) {
        await _syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.gradeConfig,
          operation: SyncOperation.setup,
          payload: {
            'class_id': classId,
            'grade_level': gradeLevel,
            'subject_group': subjectGroup,
            'school_year': schoolYear,
            if (semester != null) 'semester': semester,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: DateTime.now(),
        ));
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultVoid updateGradingConfig({
    required String classId,
    required List<Map<String, dynamic>> configs,
  }) async {
    try {
      // Save locally (optimistic)
      final now = DateTime.now().toIso8601String();
      final models = configs.map((c) => GradeConfigModel(
        id: c['id'] as String? ?? const Uuid().v4(),
        classId: classId,
        gradingPeriodNumber: (c['grading_period_number'] as num?)?.toInt() ?? (c['quarter'] as num).toInt(),
        wwWeight: (c['ww_weight'] as num).toDouble(),
        ptWeight: (c['pt_weight'] as num).toDouble(),
        qaWeight: (c['qa_weight'] as num).toDouble(),
        createdAt: now,
        updatedAt: now,
      )).toList();
      await _localDataSource.saveConfigs(models);

      // Enqueue each config update
      for (final config in configs) {
        await _syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.gradeConfig,
          operation: SyncOperation.update,
          payload: {
            'class_id': classId,
            'quarter': config['quarter'],
            'ww_weight': config['ww_weight'],
            'pt_weight': config['pt_weight'],
            'qa_weight': config['qa_weight'],
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: DateTime.now(),
        ));
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ===== Grade Items =====

  @override
  ResultFuture<List<GradeItem>> getGradeItems({
    required String classId,
    required int gradingPeriodNumber,
    String? component,
  }) async {
    try {
      print('*** GRADING REPO: getGradeItems() - classId: $classId, quarter: $gradingPeriodNumber, component: $component');
      print('*** GRADING REPO: server reachable: ${_serverReachabilityService.isServerReachable}');
      
      if (_serverReachabilityService.isServerReachable) {
        print('*** GRADING REPO: fetching from remote datasource');
        try {
          final models = await _remoteDataSource.getGradeItems(
            classId: classId,
            gradingPeriodNumber: gradingPeriodNumber,
            component: component,
          );
          print('*** GRADING REPO: got ${models.length} models from remote');
          for (final model in models) {
            print('*** GRADING REPO: remote model: ${model.title} (${model.component}) - source: ${model.sourceType}, sourceId: ${model.sourceId}');
          }
          await _localDataSource.saveItems(models);
          final entities = models.map(_itemToEntity).toList();
          print('*** GRADING REPO: converted to ${entities.length} entities, returning');
          return Right(entities);
        } catch (e) {
          print('*** GRADING REPO: Error during remote fetch: $e');
          print('*** GRADING REPO: Stack trace: ${StackTrace.current}');
          rethrow;
        }
      }
      
      print('*** GRADING REPO: server not reachable, using cache');
      final cached = await _localDataSource.getItemsByClassQuarter(
        classId,
        gradingPeriodNumber,
        component: component,
      );
      print('*** GRADING REPO: got ${cached.length} items from cache');
      for (final model in cached) {
        print('*** GRADING REPO: cached model: ${model.title} (${model.component}) - source: ${model.sourceType}, sourceId: ${model.sourceId}');
      }
      final entities = cached.map(_itemToEntity).toList();
      print('*** GRADING REPO: converted cached to ${entities.length} entities, returning');
      return Right(entities);
    } on ServerFailure catch (e) {
      print('*** GRADING REPO: ServerFailure: ${e.message}');
      return Left(e);
    } catch (e) {
      print('*** GRADING REPO: Exception: $e, trying cache fallback');
      try {
        final cached = await _localDataSource.getItemsByClassQuarter(
          classId,
          gradingPeriodNumber,
          component: component,
        );
        print('*** GRADING REPO: cache fallback got ${cached.length} items');
        final entities = cached.map(_itemToEntity).toList();
        return Right(entities);
      } catch (_) {
        print('*** GRADING REPO: cache fallback failed');
        return Left(CacheFailure(e.toString()));
      }
    }
  }

  @override
  ResultFuture<GradeItem> createGradeItem({
    required String classId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final now = DateTime.now();
      final id = const Uuid().v4();

      final model = GradeItemModel(
        id: id,
        classId: classId,
        title: data['title'] as String,
        component: data['component'] as String,
        gradingPeriodNumber: (data['grading_period_number'] as num?)?.toInt() ?? (data['quarter'] as num?)?.toInt() ?? 1,
        totalPoints: (data['total_points'] as num).toDouble(),
        sourceType: (data['source_type'] as String?) ?? 'manual',
        sourceId: data['source_id'] as String?,
        orderIndex: (data['order_index'] as num?)?.toInt() ?? 0,
        createdAt: now,
        updatedAt: now,
      );

      // Save locally
      await _localDataSource.saveItem(model);

      // Enqueue for sync
      await _syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.gradeItem,
        operation: SyncOperation.create,
        payload: {
          'id': id,
          'class_id': classId,
          ...data,
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: DateTime.now(),
      ));

      return Right(_itemToEntity(model));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultVoid updateGradeItem({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Update locally via raw update
      await _localDataSource.updateItemFields(id, data);

      // Enqueue for sync
      await _syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.gradeItem,
        operation: SyncOperation.update,
        payload: {
          'id': id,
          ...data,
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: DateTime.now(),
      ));

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultVoid deleteGradeItem({required String id}) async {
    try {
      // Soft-delete locally
      await _localDataSource.softDeleteItem(id);

      // Enqueue for sync
      await _syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.gradeItem,
        operation: SyncOperation.delete,
        payload: {'id': id},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: DateTime.now(),
      ));

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<GradeItem?> findGradeItemBySourceId(String sourceId) async {
    try {
      final model = await _localDataSource.getItemBySourceId(sourceId);
      return Right(model != null ? _itemToEntity(model) : null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ===== Scores =====

  @override
  ResultFuture<List<GradeScore>> getScoresByItem({
    required String gradeItemId,
  }) async {
    print('*** REPO: getScoresByItem() - START: gradeItemId=$gradeItemId');
    print('*** REPO: getScoresByItem() - Server reachable: ${_serverReachabilityService.isServerReachable}');
    
    try {
      // CACHE-FIRST STRATEGY: Always check cache first
      print('*** REPO: getScoresByItem() - Checking local cache first...');
      final cached = await _localDataSource.getScoresByItem(gradeItemId);
      print('*** REPO: getScoresByItem() - Cache returned ${cached.length} scores');
      
      // If cache has data, return it immediately (offline-first)
      if (cached.isNotEmpty) {
        final entities = cached.map(_scoreToEntity).toList();
        print('*** REPO: getScoresByItem() - SUCCESS: Returning ${entities.length} scores from cache (cache-first)');
        
        // Background sync if server is reachable, but don't wait for it
        if (_serverReachabilityService.isServerReachable) {
          print('*** REPO: getScoresByItem() - Background sync: fetching from remote to update cache...');
          _backgroundSyncScores(gradeItemId, cached.length);
        }
        
        return Right(entities);
      }
      
      // Cache is empty, try remote
      if (_serverReachabilityService.isServerReachable) {
        print('*** REPO: getScoresByItem() - Cache empty, fetching from remote server...');
        final models = await _remoteDataSource.getScoresByItem(
          gradeItemId: gradeItemId,
        );
        print('*** REPO: getScoresByItem() - Remote returned ${models.length} scores');
        
        print('*** REPO: getScoresByItem() - Saving ${models.length} scores to local cache');
        await _localDataSource.saveScores(models);
        
        final entities = models.map(_scoreToEntity).toList();
        print('*** REPO: getScoresByItem() - SUCCESS: Returning ${entities.length} scores from remote');
        return Right(entities);
      } else {
        print('*** REPO: getScoresByItem() - Cache empty and server not reachable');
        final entities = cached.map(_scoreToEntity).toList();
        print('*** REPO: getScoresByItem() - SUCCESS: Returning ${entities.length} empty scores from cache');
        return Right(entities);
      }
    } on ServerFailure catch (e) {
      print('*** REPO: getScoresByItem() - Server failure: ${e.toString()}, trying cache...');
      return Left(e);
    } on Failure catch (e) {
      print('*** REPO: getScoresByItem() - General failure: ${e.toString()}, trying cache...');
      return Left(e);
    } catch (e) {
      print('*** REPO: getScoresByItem() - Unexpected exception: ${e.toString()}, trying cache...');
      try {
        final cached = await _localDataSource.getScoresByItem(gradeItemId);
        print('*** REPO: getScoresByItem() - Fallback cache returned ${cached.length} scores');
        return Right(cached.map(_scoreToEntity).toList());
      } catch (_) {
        print('*** REPO: getScoresByItem() - ERROR: Cache fallback failed: ${e.toString()}');
        return Left(CacheFailure(e.toString()));
      }
    }
  }

  /// Background sync to update cache without blocking UI
  Future<void> _backgroundSyncScores(String gradeItemId, int currentCacheCount) async {
    try {
      final models = await _remoteDataSource.getScoresByItem(gradeItemId: gradeItemId);
      print('*** REPO: _backgroundSyncScores() - Background sync got ${models.length} scores');
      
      // Only update cache if remote has more data than current cache
      if (models.length > currentCacheCount) {
        print('*** REPO: _backgroundSyncScores() - Updating cache with ${models.length} remote scores');
        await _localDataSource.saveScores(models);
      } else {
        print('*** REPO: _backgroundSyncScores() - Remote has same or fewer scores, keeping cache data');
      }
    } catch (e) {
      print('*** REPO: _backgroundSyncScores() - Background sync failed: ${e.toString()}');
    }
  }

  @override
  ResultVoid saveScores({
    required String gradeItemId,
    required List<Map<String, dynamic>> scores,
  }) async {
    print('*** REPO: saveScores() - START: gradeItemId=$gradeItemId, scoresCount=${scores.length}');
    
    try {
      // Basic validation of grade item ID format
      if (gradeItemId.isEmpty) {
        print('*** REPO: saveScores() - WARNING: Empty grade item ID, skipping sync enqueue');
        return const Right(null);
      }

      final now = DateTime.now().toIso8601String();

      // Save each score locally (optimistic)
      print('*** REPO: saveScores() - Creating ${scores.length} score models');
      final models = scores.map((s) {
        final scoreId = s['id'] as String? ?? const Uuid().v4();
        final studentId = s['student_id'] as String;
        final scoreValue = (s['score'] as num).toDouble();
        final isAutoPopulated = s['is_auto_populated'] == true || s['is_auto_populated'] == 1;
        print('*** REPO: saveScores() - Score model: id=$scoreId, studentId=$studentId, score=$scoreValue, isAutoPopulated=$isAutoPopulated');
        
        return GradeScoreModel(
          id: scoreId,
          gradeItemId: gradeItemId,
          studentId: studentId,
          score: scoreValue,
          isAutoPopulated: isAutoPopulated,
          overrideScore: null,
          createdAt: now,
          updatedAt: now,
        );
      }).toList();
      
      print('*** REPO: saveScores() - Upserting ${models.length} scores to local database');
      // upsertScoresByItem enqueues the sync operation transactionally — no second enqueue needed.
      await _localDataSource.upsertScoresByItem(gradeItemId, models);
      print('*** REPO: saveScores() - SUCCESS: Saved ${models.length} scores (sync enqueued by upsert)');

      return const Right(null);
    } catch (e) {
      print('*** REPO: saveScores() - ERROR: ${e.toString()}');
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultVoid setScoreOverride({
    required String scoreId,
    required double overrideScore,
  }) async {
    try {
      // Update locally
      await _localDataSource.updateScoreOverride(scoreId, overrideScore);

      // Enqueue for sync
      await _syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.gradeScore,
        operation: SyncOperation.setOverride,
        payload: {
          'score_id': scoreId,
          'override_score': overrideScore,
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: DateTime.now(),
      ));

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultVoid clearScoreOverride({required String scoreId}) async {
    try {
      // Clear locally
      await _localDataSource.updateScoreOverride(scoreId, null);

      // Enqueue for sync
      await _syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.gradeScore,
        operation: SyncOperation.clearOverride,
        payload: {'score_id': scoreId},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: DateTime.now(),
      ));

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ===== Computed Grades =====

  @override
  ResultFuture<List<PeriodGrade>> getPeriodGrades({
    required String classId,
    required int gradingPeriodNumber,
  }) async {
    try {
      if (_serverReachabilityService.isServerReachable) {
        final models = await _remoteDataSource.getPeriodGrades(
          classId: classId,
          gradingPeriodNumber: gradingPeriodNumber,
        );
        await _localDataSource.savePeriodGrades(models);
        return Right(models.map(_periodToEntity).toList());
      }
      final cached = await _localDataSource.getPeriodGradesByClass(
        classId,
        gradingPeriodNumber,
      );
      return Right(cached.map(_periodToEntity).toList());
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      try {
        final cached = await _localDataSource.getPeriodGradesByClass(
          classId,
          gradingPeriodNumber,
        );
        return Right(cached.map(_periodToEntity).toList());
      } catch (_) {
        return Left(CacheFailure(e.toString()));
      }
    }
  }

  @override
  ResultVoid computeGrades({
    required String classId,
    required int gradingPeriodNumber,
  }) async {
    try {
      await _remoteDataSource.computeGrades(
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
      );
      return const Right(null);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultVoid updateTransmutedGrade({
    required String classId,
    required String studentId,
    required int gradingPeriodNumber,
    required int transmutedGrade,
  }) async {
    try {
      await _localDataSource.updateTransmutedGrade(
        classId,
        studentId,
        gradingPeriodNumber,
        transmutedGrade,
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<Map<String, dynamic>>> getGradeSummary({
    required String classId,
    required int gradingPeriodNumber,
  }) async {
    try {
      final summary = await _remoteDataSource.getGradeSummary(
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
      );
      return Right(summary);
    } on ServerFailure catch (e) {
      // Propagate server errors (e.g. 400 "Grading config not set up") so the
      // UI can show a "syncing to server" banner instead of blank grades.
      return Left(e);
    } on Failure {
      return const Right([]);
    } catch (_) {
      return const Right([]);
    }
  }

  @override
  ResultFuture<List<Map<String, dynamic>>> getFinalGrades({
    required String classId,
  }) async {
    try {
      final grades = await _remoteDataSource.getFinalGrades(classId: classId);
      return Right(grades);
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ===== Student =====

  @override
  ResultFuture<List<PeriodGrade>> getMyGrades({
    required String classId,
  }) async {
    try {
      if (_serverReachabilityService.isServerReachable) {
        final models = await _remoteDataSource.getMyGrades(classId: classId);
        await _localDataSource.savePeriodGrades(models);
        return Right(models.map(_periodToEntity).toList());
      }
      return const Right([]);
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<Map<String, dynamic>> getMyGradeDetail({
    required String classId,
    required int gradingPeriodNumber,
  }) async {
    try {
      final detail = await _remoteDataSource.getMyGradeDetail(
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
      );
      return Right(detail);
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ===== General Average =====

  @override
  ResultFuture<GeneralAverageResponse> getGeneralAverages({
    required String classId,
  }) async {
    try {
      final model = await _remoteDataSource.getGeneralAverages(
        classId: classId,
      );
      return Right(model);
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ===== SF9/SF10 =====

  @override
  ResultFuture<Sf9Response> getSf9({
    required String classId,
    required String studentId,
  }) async {
    try {
      final model = await _remoteDataSource.getSf9(
        classId: classId,
        studentId: studentId,
      );
      return Right(model);
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<Sf9Response> getSf10({
    required String classId,
    required String studentId,
  }) async {
    try {
      final model = await _remoteDataSource.getSf10(
        classId: classId,
        studentId: studentId,
      );
      return Right(model);
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<Map<String, dynamic>> getGradeDataBatch({
    required String classId,
    required int gradingPeriodNumber,
  }) async {
    try {
      // For now, implement batch loading by combining individual calls
      // This can be optimized later with a proper batch endpoint
      final gradeItemsResult = await getGradeItems(
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
      );
      
      final gradeSummaryResult = await getGradeSummary(
        classId: classId,
        gradingPeriodNumber: gradingPeriodNumber,
      );
      
      return gradeItemsResult.fold(
        (failure) => Left(failure),
        (gradeItems) => gradeSummaryResult.fold(
          (failure) => Left(failure),
          (gradeSummary) => Right({
            'grade_items': gradeItems.map((item) => GradeItemModel(
              id: item.id,
              classId: item.classId,
              title: item.title,
              component: item.component,
              gradingPeriodNumber: item.gradingPeriodNumber,
              totalPoints: item.totalPoints,
              sourceType: item.sourceType,
              sourceId: item.sourceId,
              orderIndex: item.orderIndex,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
            ).toJson()).toList(),
            'grade_summary': gradeSummary,
            'quarter': gradingPeriodNumber,
          }),
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
