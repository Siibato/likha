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
import 'package:likha/data/models/grading/quarterly_grade_model.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/domain/grading/entities/quarterly_grade.dart';
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
        quarter: m.quarter,
        wwWeight: m.wwWeight,
        ptWeight: m.ptWeight,
        qaWeight: m.qaWeight,
      );

  GradeItem _itemToEntity(GradeItemModel m) => GradeItem(
        id: m.id,
        classId: m.classId,
        title: m.title,
        component: m.component,
        quarter: m.quarter,
        totalPoints: m.totalPoints,
        isDepartmentalExam: m.isDepartmentalExam,
        sourceType: m.sourceType,
        sourceId: m.sourceId,
        orderIndex: m.orderIndex,
      );

  GradeScore _scoreToEntity(GradeScoreModel m) => GradeScore(
        id: m.id,
        gradeItemId: m.gradeItemId,
        studentId: m.studentId,
        score: m.score,
        isAutoPopulated: m.isAutoPopulated,
        overrideScore: m.overrideScore,
      );

  QuarterlyGrade _quarterlyToEntity(QuarterlyGradeModel m) => QuarterlyGrade(
        id: m.id,
        classId: m.classId,
        studentId: m.studentId,
        quarter: m.quarter,
        wwPercentage: m.wwPercentage,
        ptPercentage: m.ptPercentage,
        qaPercentage: m.qaPercentage,
        wwWeighted: m.wwWeighted,
        ptWeighted: m.ptWeighted,
        qaWeighted: m.qaWeighted,
        initialGrade: m.initialGrade,
        transmutedGrade: m.transmutedGrade,
        isComplete: m.isComplete,
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
      if (_serverReachabilityService.isServerReachable) {
        final models = await _remoteDataSource.getGradingConfig(
          classId: classId,
        );
        await _localDataSource.saveConfigs(models);
        return Right(models.map(_configToEntity).toList());
      }
      final cached = await _localDataSource.getConfigByClass(classId);
      return Right(cached.map(_configToEntity).toList());
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      try {
        final cached = await _localDataSource.getConfigByClass(classId);
        return Right(cached.map(_configToEntity).toList());
      } catch (_) {
        return Left(CacheFailure(e.toString()));
      }
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
      // Save locally first (optimistic)
      final weights = _weightPresets[subjectGroup];
      if (weights != null) {
        final now = DateTime.now().toIso8601String();
        final configs = <GradeConfigModel>[];
        // Create config for quarter 1 (default)
        configs.add(GradeConfigModel(
          id: const Uuid().v4(),
          classId: classId,
          quarter: 1,
          wwWeight: weights.ww,
          ptWeight: weights.pt,
          qaWeight: weights.qa,
          createdAt: now,
          updatedAt: now,
        ));
        await _localDataSource.saveConfigs(configs);
      }

      // Enqueue for sync
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

      // If online, also call remote (for immediate server-side processing)
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
        } catch (_) {
          // Remote call failed — sync queue will handle it
        }
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
        quarter: (c['quarter'] as num).toInt(),
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
    required int quarter,
    String? component,
  }) async {
    try {
      if (_serverReachabilityService.isServerReachable) {
        final models = await _remoteDataSource.getGradeItems(
          classId: classId,
          quarter: quarter,
          component: component,
        );
        await _localDataSource.saveItems(models);
        return Right(models.map(_itemToEntity).toList());
      }
      final cached = await _localDataSource.getItemsByClassQuarter(
        classId,
        quarter,
        component: component,
      );
      return Right(cached.map(_itemToEntity).toList());
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      try {
        final cached = await _localDataSource.getItemsByClassQuarter(
          classId,
          quarter,
          component: component,
        );
        return Right(cached.map(_itemToEntity).toList());
      } catch (_) {
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
      final now = DateTime.now().toIso8601String();
      final id = const Uuid().v4();

      final model = GradeItemModel(
        id: id,
        classId: classId,
        title: data['title'] as String,
        component: data['component'] as String,
        quarter: (data['quarter'] as num).toInt(),
        totalPoints: (data['total_points'] as num).toDouble(),
        isDepartmentalExam: data['is_departmental_exam'] == true,
        sourceType: 'manual',
        sourceId: null,
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

  // ===== Scores =====

  @override
  ResultFuture<List<GradeScore>> getScoresByItem({
    required String gradeItemId,
  }) async {
    try {
      if (_serverReachabilityService.isServerReachable) {
        final models = await _remoteDataSource.getScoresByItem(
          gradeItemId: gradeItemId,
        );
        await _localDataSource.saveScores(models);
        return Right(models.map(_scoreToEntity).toList());
      }
      final cached = await _localDataSource.getScoresByItem(gradeItemId);
      return Right(cached.map(_scoreToEntity).toList());
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      try {
        final cached = await _localDataSource.getScoresByItem(gradeItemId);
        return Right(cached.map(_scoreToEntity).toList());
      } catch (_) {
        return Left(CacheFailure(e.toString()));
      }
    }
  }

  @override
  ResultVoid saveScores({
    required String gradeItemId,
    required List<Map<String, dynamic>> scores,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();

      // Save each score locally (optimistic)
      final models = scores.map((s) => GradeScoreModel(
        id: const Uuid().v4(),
        gradeItemId: gradeItemId,
        studentId: s['student_id'] as String,
        score: (s['score'] as num).toDouble(),
        isAutoPopulated: false,
        overrideScore: null,
        createdAt: now,
        updatedAt: now,
      )).toList();
      await _localDataSource.upsertScoresByItem(gradeItemId, models);

      // Enqueue batch save for sync
      await _syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.gradeScore,
        operation: SyncOperation.saveScores,
        payload: {
          'grade_item_id': gradeItemId,
          'scores': scores,
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
  ResultFuture<List<QuarterlyGrade>> getQuarterlyGrades({
    required String classId,
    required int quarter,
  }) async {
    try {
      if (_serverReachabilityService.isServerReachable) {
        final models = await _remoteDataSource.getQuarterlyGrades(
          classId: classId,
          quarter: quarter,
        );
        await _localDataSource.saveQuarterlyGrades(models);
        return Right(models.map(_quarterlyToEntity).toList());
      }
      final cached = await _localDataSource.getQuarterlyGradesByClass(
        classId,
        quarter,
      );
      return Right(cached.map(_quarterlyToEntity).toList());
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      try {
        final cached = await _localDataSource.getQuarterlyGradesByClass(
          classId,
          quarter,
        );
        return Right(cached.map(_quarterlyToEntity).toList());
      } catch (_) {
        return Left(CacheFailure(e.toString()));
      }
    }
  }

  @override
  ResultVoid computeGrades({
    required String classId,
    required int quarter,
  }) async {
    try {
      await _remoteDataSource.computeGrades(
        classId: classId,
        quarter: quarter,
      );
      return const Right(null);
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<Map<String, dynamic>>> getGradeSummary({
    required String classId,
    required int quarter,
  }) async {
    try {
      final summary = await _remoteDataSource.getGradeSummary(
        classId: classId,
        quarter: quarter,
      );
      return Right(summary);
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
  ResultFuture<List<QuarterlyGrade>> getMyGrades({
    required String classId,
  }) async {
    try {
      if (_serverReachabilityService.isServerReachable) {
        final models = await _remoteDataSource.getMyGrades(classId: classId);
        await _localDataSource.saveQuarterlyGrades(models);
        return Right(models.map(_quarterlyToEntity).toList());
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
    required int quarter,
  }) async {
    try {
      final detail = await _remoteDataSource.getMyGradeDetail(
        classId: classId,
        quarter: quarter,
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
}
