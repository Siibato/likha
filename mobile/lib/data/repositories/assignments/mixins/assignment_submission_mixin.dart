import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/entities/submission_file.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart';
import 'package:likha/data/repositories/assignments/assignment_repository_base.dart';
import 'package:uuid/uuid.dart';

mixin AssignmentSubmissionMixin on AssignmentRepositoryBase {
  @override
  ResultFuture<List<SubmissionListItem>> getSubmissions({
    required String assignmentId,
  }) async {
    try {
      try {
        final cached =
            await localDataSource.getCachedSubmissions(assignmentId);
        return Right(cached);
      } on CacheException {
        // Not in local DB — fetch from server if reachable
        try {
          final result = await remoteDataSource.getSubmissions(
              assignmentId: assignmentId);
          await localDataSource.cacheSubmissions(
              assignmentId, result.cast<SubmissionListItemModel>());
          unawaited(validationService.validateAndSync('assignments'));
          return Right(result);
        } on NetworkException catch (e) {
          return Left(NetworkFailure(e.message));
        } on ServerException catch (e) {
          return Left(ServerFailure(e.message));
        }
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<AssignmentSubmission> getSubmissionDetail({
    required String submissionId,
  }) async {
    try {
      final cached =
          await localDataSource.getCachedSubmission(submissionId);
      if (cached != null) {
        unawaited(validationService.validateAndSync('assignments'));
        return Right(cached);
      }
    } catch (_) {}

    try {
      final result = await remoteDataSource.getSubmissionDetail(
          submissionId: submissionId);
      unawaited(localDataSource.cacheSubmissionDetail(result));
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
      if (!serverReachabilityService.isServerReachable) {
        await localDataSource.gradeSubmissionLocally(
          submissionId: submissionId,
          score: score,
          feedback: feedback,
        );
        // Read back the now-updated cached row for response
        final cached = await localDataSource.getCachedSubmission(submissionId);
        if (cached != null) return Right(cached);
        // Fallback (shouldn't happen — submission was just graded from UI which loaded it)
        return Right(AssignmentSubmission(
          id: submissionId,
          assignmentId: '',
          studentId: '',
          studentName: '',
          status: 'graded',
          isLate: false,
          score: score,
          feedback: feedback,
          files: const [],
          textContent: null,
          submittedAt: DateTime.now(),
          gradedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      final result = await remoteDataSource.gradeSubmission(
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
      if (!serverReachabilityService.isServerReachable) {
        await localDataSource.returnSubmissionLocally(
          submissionId: submissionId,
        );
        final cached = await localDataSource.getCachedSubmission(submissionId);
        if (cached != null) return Right(cached);
        return Right(AssignmentSubmission(
          id: submissionId,
          assignmentId: '',
          studentId: '',
          studentName: '',
          status: 'returned',
          isLate: false,
          files: const [],
          textContent: null,
          score: null,
          feedback: null,
          submittedAt: DateTime.now(),
          gradedAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      final result = await remoteDataSource.returnSubmission(
          submissionId: submissionId);
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
      if (!serverReachabilityService.isServerReachable) {
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assignmentSubmission,
          operation: SyncOperation.create,
          payload: {
            'assignment_id': assignmentId,
            if (textContent != null) 'text_content': textContent,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));

        return Right(AssignmentSubmission(
          id: '',
          assignmentId: assignmentId,
          studentId: '',
          studentName: '',
          status: 'draft',
          textContent: textContent,
          score: null,
          feedback: null,
          isLate: false,
          files: const [],
          submittedAt: null,
          gradedAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      final result = await remoteDataSource.createSubmission(
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
      if (!serverReachabilityService.isServerReachable) {
        final size = await fileSize(filePath);
        final mime = mimeType(filePath);

        await localDataSource.stageFileForUpload(
          submissionId: submissionId,
          fileName: fileName,
          fileType: mime,
          fileSize: size,
          localPath: filePath,
        );

        return Right(SubmissionFile(
          id: '',
          fileName: fileName,
          fileType: mime,
          fileSize: size,
          uploadedAt: DateTime.now(),
        ));
      }

      final result = await remoteDataSource.uploadFile(
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
      if (!serverReachabilityService.isServerReachable) {
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.submissionFile,
          operation: SyncOperation.delete,
          payload: {'file_id': fileId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));
        return const Right(null);
      }

      await remoteDataSource.deleteFile(fileId: fileId);
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
      if (!serverReachabilityService.isServerReachable) {
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assignmentSubmission,
          operation: SyncOperation.submit,
          payload: {
            'id': submissionId,
            'submitted_at': DateTime.now().toIso8601String(),
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));

        return Right(AssignmentSubmission(
          id: submissionId,
          assignmentId: '',
          studentId: '',
          studentName: '',
          status: 'submitted',
          textContent: null,
          score: null,
          feedback: null,
          isLate: false,
          files: const [],
          submittedAt: DateTime.now(),
          gradedAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      final result = await remoteDataSource.submitAssignment(
          submissionId: submissionId);

      // Best-effort: cache submission detail for offline viewing
      try {
        await localDataSource.cacheSubmissions(
          result.assignmentId,
          [SubmissionListItemModel(
            id: result.id,
            studentId: result.studentId,
            studentName: result.studentName,
            status: result.status,
            submittedAt: result.submittedAt,
            isLate: result.isLate,
            score: result.score,
          )],
        );
      } catch (_) {
        // Silently fail — don't block submission if cache write fails
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
  ResultFuture<List<int>> downloadFile({required String fileId}) async {
    try {
      if (await localDataSource.isFileCached(fileId)) {
        final cachedBytes = await localDataSource.getCachedFileBytes(fileId);
        return Right(cachedBytes);
      }

      final result = await remoteDataSource.downloadFile(fileId: fileId);
      try {
        await localDataSource.cacheFileBytes(fileId, fileId, result);
      } catch (_) {}
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
