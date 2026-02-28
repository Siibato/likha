import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/validation/services/validation_service.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/entity_sync_helper.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/services/storage_service.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/data/datasources/local/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/class_remote_datasource.dart';
import 'package:likha/data/models/classes/class_model.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';

class ClassRepositoryImpl implements ClassRepository {
  final ClassRemoteDataSource _remoteDataSource;
  final ClassLocalDataSource _localDataSource;
  final ValidationService _validationService;
  final ServerReachabilityService _serverReachabilityService;
  final EntitySyncHelper _entitySyncHelper;
  final SyncQueue _syncQueue;
  final StorageService _storageService;

  ClassRepositoryImpl({
    required ClassRemoteDataSource remoteDataSource,
    required ClassLocalDataSource
     localDataSource,
    required ValidationService validationService,
    required ServerReachabilityService serverReachabilityService,
    required EntitySyncHelper entitySyncHelper,
    required SyncQueue syncQueue,
    required StorageService storageService,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _validationService = validationService,
        _serverReachabilityService = serverReachabilityService,
        _entitySyncHelper = entitySyncHelper,
        _syncQueue = syncQueue,
        _storageService = storageService;

  @override
  ResultFuture<ClassEntity> createClass({
    required String title,
    String? description,
  }) async {
    try {
      // Check server reachability
      if (!_serverReachabilityService.isServerReachable) {
        // Generate a local UUID for tracking
        final localId = const Uuid().v4();

        // Offline: queue the mutation locally with typed enums
        final entry = SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.classEntity,
          operation: SyncOperation.create,
          payload: {
            'local_id': localId, // Include local_id for ID reconciliation
            'title': title,
            'description': description,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        await _syncQueue.enqueue(entry);

        // Create optimistic model with local UUID
        final now = DateTime.now();
        final optimisticModel = ClassModel(
          id: localId, // Use local UUID instead of empty string
          title: title,
          description: description,
          teacherId: '',
          teacherUsername: '',
          teacherFullName: '',
          isArchived: false,
          studentCount: 0,
          createdAt: now,
          updatedAt: now,
        );

        // Cache the optimistic class immediately so it appears in the list
        try {
          final currentUserId = await _getCurrentUserId();
          final cached = await _localDataSource.getCachedClasses(teacherId: currentUserId);
          await _localDataSource.cacheClasses([optimisticModel, ...cached]);
        } catch (_) {
          // If cache is empty or doesn't exist yet, just cache this one
          await _localDataSource.cacheClasses([optimisticModel]);
        }

        return Right(optimisticModel);
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
      // Get current user ID for filtering cached data
      final currentUserId = await _getCurrentUserId();

      // Step 1: Return cached data immediately (cache-first pattern)
      try {
        final cachedClasses = await _localDataSource.getCachedClasses(teacherId: currentUserId);

        // Step 2: Sync in background (don't await)
        _syncClassesInBackground();

        return Right(cachedClasses);
      } on CacheException {
        // Cache empty, try to fetch from server
        final freshClasses = await _remoteDataSource.getMyClasses();
        await _localDataSource.cacheClasses(freshClasses);

        // Eagerly cache each class detail so enrollments are available offline
        for (final cls in freshClasses) {
          try {
            final detail = await _remoteDataSource.getClassDetail(classId: cls.id);
            await _localDataSource.cacheClassDetail(detail);
          } catch (_) {
            // Best-effort: if individual class detail fetch fails, continue with others
          }
        }

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

      // Eagerly cache each class detail so enrollments are available offline
      for (final cls in remoteClasses) {
        try {
          final detail = await _remoteDataSource.getClassDetail(classId: cls.id);
          await _localDataSource.cacheClassDetail(detail);
        } catch (_) {
          // Best-effort: if individual class detail fetch fails, continue with others
        }
      }
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
        } on CacheException {
          // Primary cache doesn't exist, try to rebuild from enrollments
          try {
            final rebuilt = await _localDataSource.buildClassDetailFromEnrollments(classId);
            if (rebuilt != null) {
              return Right(rebuilt);
            }
            // No enrollments or class data available
            return Left(CacheFailure('Class detail not available offline'));
          } catch (e) {
            return Left(CacheFailure('Failed to load class detail offline'));
          }
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
      // Check server reachability
      if (!_serverReachabilityService.isServerReachable) {
        // Offline: queue the mutation locally
        final entry = SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.classEntity,
          operation: SyncOperation.update,
          payload: {
            'id': classId,
            'title': title,
            'description': description,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        await _syncQueue.enqueue(entry);

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
      // Check server reachability
      if (!_serverReachabilityService.isServerReachable) {
        // Check existing local enrollment to prevent duplicate queue entry
        try {
          final alreadyEnrolled = await _localDataSource.getEnrolledStudentIds(classId);
          if (alreadyEnrolled.contains(studentId)) {
            // Return the already-cached enrollment as success — no re-queue needed
            final cachedStudent = await _localDataSource.getStudentById(studentId);
            final s = cachedStudent ?? UserModel(
              id: studentId, username: '', fullName: '',
              role: 'student', accountStatus: 'active',
              isActive: true, activatedAt: null, createdAt: DateTime.now(),
            );
            return Right(Enrollment(id: '', student: s, enrolledAt: DateTime.now()));
          }
        } catch (_) {}

        // Look up cached student by ID
        UserModel? cachedStudent;
        try {
          cachedStudent = await _localDataSource.getStudentById(studentId);
        } catch (_) {}

        // Skeleton if cache miss — names fill in after sync
        final studentModel = cachedStudent ?? UserModel(
          id: studentId, username: '', fullName: '',
          role: 'student', accountStatus: 'active',
          isActive: true, activatedAt: null, createdAt: DateTime.now(),
        );

        // Persist enrollment to local DB so it survives app restarts
        String? enrollmentId;
        try {
          enrollmentId = await _localDataSource.addStudentLocally(classId: classId, student: studentModel);
        } catch (_) {}

        // Queue sync
        final payload = <String, dynamic>{
          'class_id': classId, 'student_id': studentId,
          if (cachedStudent != null) 'student_username': cachedStudent.username,
          if (cachedStudent != null) 'student_full_name': cachedStudent.fullName,
          if (enrollmentId != null) 'local_enrollment_id': enrollmentId,
        };
        await _syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.classEntity,
          operation: SyncOperation.addEnrollment,
          payload: payload,
          status: SyncStatus.pending, retryCount: 0, maxRetries: 5,
          createdAt: DateTime.now(),
        ));

        // Refresh class detail cache with the newly added student
        // This ensures offline-added students are visible in cached data
        try {
          await _localDataSource.getCachedClassDetail(classId);
        } catch (_) {
          // Cache refresh failure is non-critical - enrollment is still queued for sync
        }

        return Right(Enrollment(id: '', student: studentModel, enrolledAt: DateTime.now()));
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
      // Check server reachability
      if (!_serverReachabilityService.isServerReachable) {
        // Remove from local DB so it doesn't reappear on restart
        try {
          await _localDataSource.removeStudentLocally(classId: classId, studentId: studentId);
        } catch (_) {}

        // Queue sync
        await _syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.classEntity,
          operation: SyncOperation.removeEnrollment,
          payload: {'class_id': classId, 'student_id': studentId},
          status: SyncStatus.pending, retryCount: 0, maxRetries: 5,
          createdAt: DateTime.now(),
        ));

        // Refresh class detail cache with the removed student
        // This ensures offline-removed students are no longer visible in cached data
        try {
          await _localDataSource.getCachedClassDetail(classId);
        } catch (_) {
          // Cache refresh failure is non-critical - removal is still queued for sync
        }

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

      // Persist results to local cache for offline access
      try {
        await _localDataSource.cacheSearchStudents(result);
      } catch (e) {
        // Caching failure must not block the online result
      }

      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      // Server unreachable — fall back to cached students
      try {
        final cached = await _localDataSource.searchCachedStudents(query ?? '');
        if (cached.isNotEmpty) {
          return Right(cached);
        }
      } catch (cacheError) {
        // Cache lookup failed; fall through to network error
      }
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Get the current user ID from secure storage
  /// Returns null if offline or no user is logged in
  Future<String?> _getCurrentUserId() async {
    try {
      return await _storageService.getUserId();
    } catch (e) {
      return null;
    }
  }
}
