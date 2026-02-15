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
      // Step 1: Load from SQLite immediately (instant - no wait)
      final cachedClasses = await _localDataSource.getCachedClasses();

      // Step 2: Validate freshness in background (non-blocking)
      // This runs while UI is displaying cached data
      unawaited(_validationService.validateAndSync('classes'));

      // Step 3: Return cached data immediately
      return Right(cachedClasses);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<ClassDetail> getClassDetail({required String classId}) async {
    try {
      // Load from SQLite immediately
      final cached = await _localDataSource.getCachedClassDetail(classId);

      // Validate freshness in background
      unawaited(_validationService.validateAndSync('classes'));

      return Right(cached);
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
