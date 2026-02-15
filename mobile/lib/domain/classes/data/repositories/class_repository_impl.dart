import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/validation/services/validation_service.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/classes/data/datasources/class_local_datasource.dart';
import 'package:likha/domain/classes/data/datasources/class_remote_datasource.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';

class ClassRepositoryImpl implements ClassRepository {
  final ClassRemoteDataSource _remoteDataSource;
  final ClassLocalDataSource _localDataSource;
  final ValidationService _validationService;

  ClassRepositoryImpl({
    required ClassRemoteDataSource remoteDataSource,
    required ClassLocalDataSource localDataSource,
    required ValidationService validationService,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _validationService = validationService;

  @override
  ResultFuture<ClassEntity> createClass({
    required String title,
    String? description,
  }) async {
    try {
      final result = await _remoteDataSource.createClass(
        title: title,
        description: description,
      );

      // After creating a new class, refetch the full list to include it in cache
      try {
        final freshClasses = await _remoteDataSource.getMyClasses();
        await _localDataSource.cacheClasses(freshClasses);
      } catch (e) {
        // If refetch fails, that's OK - user will see it on next list refresh
      }

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
      // Step 1: Validate and update metadata (this clears cache if outdated)
      await _validationService.validateAndSync('classes');

      // Step 2: Try to load from cache
      try {
        final cachedClasses = await _localDataSource.getCachedClasses();

        // If cache is empty (validation cleared it), refetch
        if (cachedClasses.isEmpty) {
          final freshClasses = await _remoteDataSource.getMyClasses();
          await _localDataSource.cacheClasses(freshClasses);
          return Right(freshClasses);
        }

        return Right(cachedClasses);
      } on CacheException {
        // Cache empty or error, refetch from server
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
      final result = await _remoteDataSource.updateClass(
        classId: classId,
        title: title,
        description: description,
      );
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
      final result = await _remoteDataSource.addStudent(
        classId: classId,
        studentId: studentId,
      );
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
      await _remoteDataSource.removeStudent(
        classId: classId,
        studentId: studentId,
      );
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
