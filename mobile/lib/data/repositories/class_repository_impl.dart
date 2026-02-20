import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/validation/services/validation_service.dart';
import 'package:likha/core/network/connectivity_service.dart';
import 'package:likha/core/sync/entity_sync_helper.dart';
import 'package:likha/core/sync/sync_queue_manager.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/data/datasources/local/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/class_remote_datasource.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';

class ClassRepositoryImpl implements ClassRepository {
  final ClassRemoteDataSource _remoteDataSource;
  final ClassLocalDataSource _localDataSource;
  final ValidationService _validationService;
  final ConnectivityService _connectivityService;
  final EntitySyncHelper _entitySyncHelper;
  final SyncQueueManager _syncQueueManager;

  ClassRepositoryImpl({
    required ClassRemoteDataSource remoteDataSource,
    required ClassLocalDataSource localDataSource,
    required ValidationService validationService,
    required ConnectivityService connectivityService,
    required EntitySyncHelper entitySyncHelper,
    required SyncQueueManager syncQueueManager,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _validationService = validationService,
        _connectivityService = connectivityService,
        _entitySyncHelper = entitySyncHelper,
        _syncQueueManager = syncQueueManager;

  @override
  ResultFuture<ClassEntity> createClass({
    required String title,
    String? description,
  }) async {
    try {
      // Check connectivity
      if (!_connectivityService.isOnline) {
        // Offline: queue the mutation locally
        await _syncQueueManager.enqueue(
          entityType: 'class',
          operation: 'create',
          payload: {
            'title': title,
            'description': description,
          },
        );

        // Return optimistic entity for UI
        final optimisticClass = ClassEntity(
          id: '',
          title: title,
          description: description,
          teacherId: '',
          teacherUsername: '',
          teacherFullName: '',
          isArchived: false,
          studentCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        return Right(optimisticClass);
      }

      // Online: send to server
      final result = await _remoteDataSource.createClass(
        title: title,
        description: description,
      );

      // After creating a new class, trigger background sync
      _syncInBackgroundForClass(result.id);

      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<ClassEntity>> getMyClasses() async {
    try {
      // Step 1: Return cached data immediately (cache-first pattern)
      try {
        final cachedClasses = await _localDataSource.getCachedClasses();

        // Step 2: Sync in background (don't await)
        _syncClassesInBackground();

        return Right(cachedClasses);
      } on CacheException {
        // Cache empty, try to fetch from server
        final freshClasses = await _remoteDataSource.getMyClasses();
        await _localDataSource.cacheClasses(freshClasses);
        return Right(freshClasses);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Sync classes in background by comparing timestamps
  Future<void> _syncClassesInBackground() async {
    try {
      // Fetch fresh list from server
      final remoteClasses = await _remoteDataSource.getMyClasses();

      // Batch sync by timestamp comparison
      await _entitySyncHelper.syncEntitiesByTimestamp(
        entityType: 'class',
        remoteEntities: remoteClasses
            .map((e) => {
                  'id': e.id,
                  'updated_at': e.updatedAt.toIso8601String(),
                })
            .toList(),
      );

      // Update local cache with fresh data
      await _localDataSource.cacheClasses(remoteClasses);
    } catch (e) {
      // Best-effort: if sync fails, continue with cached data
    }
  }

  /// Sync a specific class in background
  Future<void> _syncInBackgroundForClass(String classId) async {
    try {
      final remoteClass = await _remoteDataSource.getClassDetail(
        classId: classId,
      );

      // Cache the updated class
      await _localDataSource.cacheClassDetail(remoteClass);
    } catch (e) {
      // Best-effort
    }
  }

  @override
  ResultFuture<ClassDetail> getClassDetail({required String classId}) async {
    try {
      // Always try to fetch fresh class details from server for real-time updates
      try {
        final fresh = await _remoteDataSource.getClassDetail(classId: classId);
        await _localDataSource.cacheClassDetail(fresh);
        return Right(fresh);
      } on NetworkException {
        // Network unavailable, fall back to cache
        try {
          final cached = await _localDataSource.getCachedClassDetail(classId);
          return Right(cached);
        } on CacheException catch (e) {
          return Left(CacheFailure(e.message));
        }
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<ClassEntity> updateClass({
    required String classId,
    String? title,
    String? description,
  }) async {
    try {
      // Check connectivity
      if (!_connectivityService.isOnline) {
        // Offline: queue the mutation locally
        await _syncQueueManager.enqueue(
          entityType: 'class',
          operation: 'update',
          payload: {
            'id': classId,
            'title': title,
            'description': description,
          },
        );

        // Return optimistic entity
        try {
          final current = await _localDataSource
              .getCachedClasses()
              .then((classes) => classes.firstWhere(
                    (c) => c.id == classId,
                    orElse: () => throw Exception('Class not found'),
                  ));

          return Right(
            ClassEntity(
              id: current.id,
              title: title ?? current.title,
              description: description ?? current.description,
              teacherId: current.teacherId,
              teacherUsername: current.teacherUsername,
              teacherFullName: current.teacherFullName,
              isArchived: current.isArchived,
              studentCount: current.studentCount,
              createdAt: current.createdAt,
              updatedAt: DateTime.now(),
            ),
          );
        } catch (e) {
          return Left(CacheFailure('Class not found in cache'));
        }
      }

      // Online: send to server
      final result = await _remoteDataSource.updateClass(
        classId: classId,
        title: title,
        description: description,
      );

      // Sync in background
      _syncInBackgroundForClass(classId);

      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<Enrollment> addStudent({
    required String classId,
    required String studentId,
  }) async {
    try {
      // Check connectivity
      if (!_connectivityService.isOnline) {
        // Offline: queue the mutation
        await _syncQueueManager.enqueue(
          entityType: 'class_enrollment',
          operation: 'create',
          payload: {
            'class_id': classId,
            'student_id': studentId,
          },
        );

        // Return optimistic enrollment
        return Right(
          Enrollment(
            id: '',
            student: User(
              id: studentId,
              username: '',
              fullName: '',
              role: 'student',
              accountStatus: 'active',
              isActive: true,
              activatedAt: null,
              createdAt: DateTime.now(),
            ),
            enrolledAt: DateTime.now(),
          ),
        );
      }

      // Online: send to server
      final result = await _remoteDataSource.addStudent(
        classId: classId,
        studentId: studentId,
      );

      // Sync in background
      _syncInBackgroundForClass(classId);

      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultVoid removeStudent({
    required String classId,
    required String studentId,
  }) async {
    try {
      // Check connectivity
      if (!_connectivityService.isOnline) {
        // Offline: queue the mutation
        await _syncQueueManager.enqueue(
          entityType: 'class_enrollment',
          operation: 'delete',
          payload: {
            'class_id': classId,
            'student_id': studentId,
          },
        );
        return const Right(null);
      }

      // Online: send to server
      await _remoteDataSource.removeStudent(
        classId: classId,
        studentId: studentId,
      );

      // Sync in background
      _syncInBackgroundForClass(classId);

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<User>> searchStudents({String? query}) async {
    try {
      final result = await _remoteDataSource.searchStudents(query: query);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
