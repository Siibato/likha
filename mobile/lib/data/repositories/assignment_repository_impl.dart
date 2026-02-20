import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/validation/services/validation_service.dart';
import 'package:likha/data/datasources/local/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignment_remote_datasource.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/entities/submission_file.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class AssignmentRepositoryImpl implements AssignmentRepository {
  final AssignmentRemoteDataSource _remoteDataSource;
  final AssignmentLocalDataSource _localDataSource;
  final ValidationService _validationService;

  AssignmentRepositoryImpl({
    required AssignmentRemoteDataSource remoteDataSource,
    required AssignmentLocalDataSource localDataSource,
    required ValidationService validationService,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _validationService = validationService;

  @override
  ResultFuture<Assignment> createAssignment({
    required String classId,
    required String title,
    required String instructions,
    required int totalPoints,
    required String submissionType,
    String? allowedFileTypes,
    int? maxFileSizeMb,
    required String dueAt,
  }) async {
    try {
      final result = await _remoteDataSource.createAssignment(
        classId: classId,
        data: {
          'title': title,
          'instructions': instructions,
          'total_points': totalPoints,
          'submission_type': submissionType,
          if (allowedFileTypes != null) 'allowed_file_types': allowedFileTypes,
          if (maxFileSizeMb != null) 'max_file_size_mb': maxFileSizeMb,
          'due_at': dueAt,
        },
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
  ResultFuture<List<Assignment>> getAssignments({
    required String classId,
  }) async {
    try {
      final cached = await _localDataSource.getCachedAssignments(classId);
      unawaited(_validationService.syncAssignments(classId));
      return Right(cached);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<Assignment> getAssignmentDetail({
    required String assignmentId,
  }) async {
    try {
      // Always try to fetch fresh assignment details for real-time updates
      try {
        final fresh = await _remoteDataSource.getAssignmentDetail(assignmentId: assignmentId);
        await _localDataSource.cacheAssignmentDetail(fresh);
        return Right(fresh);
      } on NetworkException {
        // Network unavailable, fall back to cache
        try {
          final cached = await _localDataSource.getCachedAssignmentDetail(assignmentId);
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
  ResultFuture<Assignment> updateAssignment({
    required String assignmentId,
    String? title,
    String? instructions,
    int? totalPoints,
    String? submissionType,
    String? allowedFileTypes,
    int? maxFileSizeMb,
    String? dueAt,
  }) async {
    try {
      final result = await _remoteDataSource.updateAssignment(
        assignmentId: assignmentId,
        data: {
          if (title != null) 'title': title,
          if (instructions != null) 'instructions': instructions,
          if (totalPoints != null) 'total_points': totalPoints,
          if (submissionType != null) 'submission_type': submissionType,
          if (allowedFileTypes != null) 'allowed_file_types': allowedFileTypes,
          if (maxFileSizeMb != null) 'max_file_size_mb': maxFileSizeMb,
          if (dueAt != null) 'due_at': dueAt,
        },
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
  ResultVoid deleteAssignment({required String assignmentId}) async {
    try {
      await _remoteDataSource.deleteAssignment(assignmentId: assignmentId);
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
  ResultFuture<Assignment> publishAssignment({
    required String assignmentId,
  }) async {
    try {
      final result = await _remoteDataSource.publishAssignment(
        assignmentId: assignmentId,
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
  ResultFuture<List<SubmissionListItem>> getSubmissions({
    required String assignmentId,
  }) async {
    try {
      final result = await _remoteDataSource.getSubmissions(
        assignmentId: assignmentId,
      );
      unawaited(_validationService.validateAndSync('assignments'));
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
  ResultFuture<AssignmentSubmission> getSubmissionDetail({
    required String submissionId,
  }) async {
    try {
      final cached = await _localDataSource.getCachedSubmission(submissionId);
      if (cached != null) {
        unawaited(_validationService.validateAndSync('assignments'));
        return Right(cached);
      }
    } catch (_) {
      // No cached data, fall through to network
    }

    try {
      final result = await _remoteDataSource.getSubmissionDetail(
        submissionId: submissionId,
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
  ResultFuture<AssignmentSubmission> gradeSubmission({
    required String submissionId,
    required int score,
    String? feedback,
  }) async {
    try {
      final result = await _remoteDataSource.gradeSubmission(
        submissionId: submissionId,
        data: {
          'score': score,
          if (feedback != null) 'feedback': feedback,
        },
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
  ResultFuture<AssignmentSubmission> returnSubmission({
    required String submissionId,
  }) async {
    try {
      final result = await _remoteDataSource.returnSubmission(
        submissionId: submissionId,
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
  ResultFuture<AssignmentSubmission> createSubmission({
    required String assignmentId,
    String? textContent,
  }) async {
    try {
      final result = await _remoteDataSource.createSubmission(
        assignmentId: assignmentId,
        textContent: textContent,
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
  ResultFuture<SubmissionFile> uploadFile({
    required String submissionId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final result = await _remoteDataSource.uploadFile(
        submissionId: submissionId,
        filePath: filePath,
        fileName: fileName,
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
  ResultVoid deleteFile({required String fileId}) async {
    try {
      await _remoteDataSource.deleteFile(fileId: fileId);
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
  ResultFuture<AssignmentSubmission> submitAssignment({
    required String submissionId,
  }) async {
    try {
      final result = await _remoteDataSource.submitAssignment(
        submissionId: submissionId,
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
  ResultFuture<List<int>> downloadFile({required String fileId}) async {
    try {
      final result = await _remoteDataSource.downloadFile(fileId: fileId);
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
