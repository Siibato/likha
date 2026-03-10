import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/data/repositories/classes/class_repository_base.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:uuid/uuid.dart';

mixin ClassEnrollmentMixin on ClassRepositoryBase {
  @override
  ResultFuture<Enrollment> addStudent({
    required String classId,
    required String studentId,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        // Prevent duplicate queue entries
        try {
          final alreadyEnrolled = await localDataSource.getEnrolledStudentIds(classId);
          if (alreadyEnrolled.contains(studentId)) {
            final cachedStudent = await localDataSource.getStudentById(studentId);
            final s = cachedStudent ?? _skeletonStudent(studentId);
            return Right(Enrollment(id: '', student: s, joinedAt: DateTime.now()));
          }
        } catch (_) {}

        UserModel? cachedStudent;
        try {
          cachedStudent = await localDataSource.getStudentById(studentId);
        } catch (_) {}

        final studentModel = cachedStudent ?? _skeletonStudent(studentId);

        String? enrollmentId;
        try {
          enrollmentId = await localDataSource.addStudentLocally(
            classId: classId,
            student: studentModel,
          );
        } catch (_) {}

        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.classEntity,
          operation: SyncOperation.addEnrollment,
          payload: {
            'class_id': classId,
            'student_id': studentId,
            if (cachedStudent != null) 'student_username': cachedStudent.username,
            if (cachedStudent != null) 'student_full_name': cachedStudent.fullName,
            if (enrollmentId != null) 'local_enrollment_id': enrollmentId,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));

        try {
          await localDataSource.getCachedClassDetail(classId);
        } catch (_) {
          // Non-critical
        }

        return Right(Enrollment(id: '', student: studentModel, joinedAt: DateTime.now()));
      }

      final result = await remoteDataSource.addStudent(
        classId: classId,
        studentId: studentId,
      );

      syncInBackgroundForClass(classId);

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
      if (!serverReachabilityService.isServerReachable) {
        try {
          await localDataSource.removeStudentLocally(
            classId: classId,
            studentId: studentId,
          );
        } catch (_) {}

        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.classEntity,
          operation: SyncOperation.removeEnrollment,
          payload: {'class_id': classId, 'student_id': studentId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));

        try {
          await localDataSource.getCachedClassDetail(classId);
        } catch (_) {
          // Non-critical
        }

        return const Right(null);
      }

      await remoteDataSource.removeStudent(
        classId: classId,
        studentId: studentId,
      );

      syncInBackgroundForClass(classId);

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
      final result = await remoteDataSource.searchStudents(query: query);

      try {
        await localDataSource.cacheSearchStudents(result);
      } catch (_) {
        // Caching failure must not block the online result
      }

      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      try {
        final cached = await localDataSource.searchCachedStudents(query ?? '');
        return Right(cached);
      } catch (_) {
        // Fall through to network error
      }
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<User>> getEnrolledStudents({required String classId}) async {
    try {
      final students = await localDataSource.getCachedEnrolledStudents(classId);
      return Right(students.cast<User>());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Builds a skeleton [UserModel] when the student is not in the local cache.
  /// Names will be filled in after the next sync.
  UserModel _skeletonStudent(String studentId) => UserModel(
        id: studentId,
        username: '',
        fullName: '',
        role: 'student',
        accountStatus: 'active',
        isActive: true,
        activatedAt: null,
        createdAt: DateTime.now(),
      );
}