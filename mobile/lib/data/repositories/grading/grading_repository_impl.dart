import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/server_reachability_service.dart';
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

  GradingRepositoryImpl({
    required GradingRemoteDataSource remoteDataSource,
    required GradingLocalDataSource localDataSource,
    required ServerReachabilityService serverReachabilityService,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _serverReachabilityService = serverReachabilityService;

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
      await _remoteDataSource.setupGrading(
        classId: classId,
        data: {
          'grade_level': gradeLevel,
          'subject_group': subjectGroup,
          'school_year': schoolYear,
          if (semester != null) 'semester': semester,
        },
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
  ResultVoid updateGradingConfig({
    required String classId,
    required List<Map<String, dynamic>> configs,
  }) async {
    try {
      await _remoteDataSource.updateGradingConfig(
        classId: classId,
        configs: configs,
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
      final model = await _remoteDataSource.createGradeItem(
        classId: classId,
        data: data,
      );
      await _localDataSource.saveItem(model);
      return Right(_itemToEntity(model));
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultVoid updateGradeItem({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _remoteDataSource.updateGradeItem(id: id, data: data);
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
  ResultVoid deleteGradeItem({required String id}) async {
    try {
      await _remoteDataSource.deleteGradeItem(id: id);
      await _localDataSource.deleteItem(id);
      return const Right(null);
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
      await _remoteDataSource.saveScores(
        gradeItemId: gradeItemId,
        scores: scores,
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
  ResultVoid setScoreOverride({
    required String scoreId,
    required double overrideScore,
  }) async {
    try {
      await _remoteDataSource.setScoreOverride(
        scoreId: scoreId,
        overrideScore: overrideScore,
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
  ResultVoid clearScoreOverride({required String scoreId}) async {
    try {
      await _remoteDataSource.clearScoreOverride(scoreId: scoreId);
      return const Right(null);
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
      // Offline fallback: we don't have a student-specific local query,
      // but saveQuarterlyGrades stores them, so return empty for now
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
