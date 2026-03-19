import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:likha/core/logging/repo_logger.dart';
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
      // Offline guard: if server is unreachable, always return from local DB
      // This ensures the teacher sees synced submissions when offline, and an empty list
      // (not an error) when submissions have never been synced for this assignment
      if (!serverReachabilityService.isServerReachable) {
        final cached =
            await localDataSource.getCachedSubmissions(assignmentId);
        return Right(cached);
      }

      try {
        final cached =
            await localDataSource.getCachedSubmissions(assignmentId);
        // Only return cache if it has data; empty cache is treated as a miss
        if (cached.isNotEmpty) {
          return Right(cached);
        }
      } on CacheException {
        // Not in local DB — fall through to remote fetch
      }

      // Cache miss or empty cache — fetch from server if reachable
      try {
        final result = await remoteDataSource.getSubmissions(
            assignmentId: assignmentId);
        await localDataSource.cacheSubmissions(
            assignmentId, result.cast<SubmissionListItemModel>());
        unawaited(validationService.validateAndSync('assignments'));

        // Sort by submittedAt ASC (drafts last) for consistent ordering with cache queries
        final sorted = [...result]..sort((a, b) {
          if (a.submittedAt == null && b.submittedAt == null) return 0;
          if (a.submittedAt == null) return 1;
          if (b.submittedAt == null) return -1;
          return a.submittedAt!.compareTo(b.submittedAt!);
        });

        return Right(sorted);
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<AssignmentSubmission> getSubmissionDetail({
    required String submissionId,
  }) async {
    try {
      // Cache-primary strategy: always return cached data if available (mirrors getMaterialDetail pattern)
      // This ensures file.localPath (written by cacheFileBytes during download) is preserved
      try {
        final cached = await localDataSource.getCachedSubmission(submissionId);
        if (cached != null) {
          // Background refresh if server is reachable (non-blocking)
          if (serverReachabilityService.isServerReachable) {
            _backgroundRefreshSubmission(submissionId);
          }
          return Right(cached);
        }
      } on CacheException {
        // Cache miss — fall through to server fetch
      }

      // Cache miss: fetch from server
      try {
        final result = await remoteDataSource.getSubmissionDetail(
            submissionId: submissionId);
        // Await cache write to ensure DB is ready for subsequent reads
        await localDataSource.cacheSubmissionDetail(result);
        unawaited(validationService.validateAndSync('assignments'));

        // Auto-repair: load from cache to restore file.localPath from disk if files exist
        // This ensures files downloaded in previous sessions show as cached on initial load
        try {
          final cached = await localDataSource.getCachedSubmission(submissionId);
          if (cached != null) {
            return Right(cached);
          }
        } catch (_) {
          // Auto-repair failed, return server result as fallback
        }
        return Right(result);
      } on NetworkException {
        // Server unreachable and cache is empty
        rethrow;
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Silently refreshes submission detail from server.
  /// Updates local cache only if data has changed.
  /// Emits DataEventBus event if files have changed so the detail page can reload.
  /// All errors are swallowed — users keep seeing cached data without interruption.
  /// ConflictAlgorithm.ignore on file inserts ensures local_path values are never overwritten.
  void _backgroundRefreshSubmission(String submissionId) {
    Future.microtask(() async {
      try {
        RepoLogger.instance.log('_backgroundRefreshSubmission() - Starting background refresh for submissionId=$submissionId');
        final fresh = await remoteDataSource.getSubmissionDetail(
            submissionId: submissionId);
        // Get currently cached data to compare against fresh
        final cached = await localDataSource.getCachedSubmission(submissionId);

        if (_submissionDataHasChanged(cached, fresh)) {
          RepoLogger.instance.log('_backgroundRefreshSubmission() - Data changed! Caching and notifying...');
          await localDataSource.cacheSubmissionDetail(fresh);
          RepoLogger.instance.log('_backgroundRefreshSubmission() - Calling dataEventBus.notifySubmissionDetailChanged($submissionId)');
          dataEventBus.notifySubmissionDetailChanged(submissionId);
        } else {
          RepoLogger.instance.log('_backgroundRefreshSubmission() - Data unchanged, no notification');
        }
      } catch (e) {
        RepoLogger.instance.error('_backgroundRefreshSubmission() - Error in background refresh', e);
      }
    });
  }

  /// Helper: checks if submission data has meaningfully changed between cached and fresh versions.
  /// Checks status, score, textContent, feedback, and files.
  bool _submissionDataHasChanged(
    AssignmentSubmission? cached,
    AssignmentSubmission fresh,
  ) {
    if (cached == null) return true;
    if (cached.status != fresh.status) return true;
    if (cached.score != fresh.score) return true;
    if (cached.textContent != fresh.textContent) return true;
    if (cached.feedback != fresh.feedback) return true;
    if (_submissionFilesHaveChanged(cached.files, fresh.files)) return true;
    return false;
  }

  /// Helper: checks if submission files have changed between cached and fresh versions.
  bool _submissionFilesHaveChanged(
    List<SubmissionFile> cached,
    List<SubmissionFile> fresh,
  ) {
    if (cached.length != fresh.length) return true;
    final cachedIds = {for (final f in cached) f.id};
    for (final f in fresh) {
      if (!cachedIds.contains(f.id)) return true;
    }
    return false;
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
          needsSync: true,
          cachedAt: DateTime.now(),
        ));
      }

      final result = await remoteDataSource.gradeSubmission(
        submissionId: submissionId,
        data: {
          'score': score,
          if (feedback != null) 'feedback': feedback,
        },
      );
      // Ensure cache is fresh before listener (ref.listen in page) re-reads it
      await localDataSource.cacheSubmissionDetail(result);
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
          needsSync: true,
          cachedAt: DateTime.now(),
        ));
      }

      final result = await remoteDataSource.returnSubmission(
          submissionId: submissionId);
      // Ensure cache is fresh before listener (ref.listen in page) re-reads it
      await localDataSource.cacheSubmissionDetail(result);
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
        final studentId = await storageService.getUserId() ?? '';
        final localId = await localDataSource.createSubmissionLocally(
          assignmentId: assignmentId,
          studentId: studentId,
          textContent: textContent,
        );
        // No direct syncQueue.enqueue — createSubmissionLocally already enqueues atomically

        return Right(AssignmentSubmission(
          id: localId,
          assignmentId: assignmentId,
          studentId: studentId,
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
          needsSync: true,
          cachedAt: DateTime.now(),
        ));
      }

      final result = await remoteDataSource.createSubmission(
        assignmentId: assignmentId,
        textContent: textContent,
      );
      // Cache submission for offline access (Fix 6)
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
  ResultFuture<SubmissionFile> uploadFile({
    required String submissionId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      if (!serverReachabilityService.isServerReachable) {
        final size = await fileSize(filePath);
        final mime = mimeType(filePath);

        final localFileId = const Uuid().v4();
        await localDataSource.stageFileForUpload(
          submissionId: submissionId,
          fileName: fileName,
          fileType: mime,
          fileSize: size,
          localPath: filePath,
        );

        return Right(SubmissionFile(
          id: localFileId,
          fileName: fileName,
          fileType: mime,
          fileSize: size,
          uploadedAt: DateTime.now(),
          localPath: filePath,
          needsSync: true,
          cachedAt: DateTime.now(),
        ));
      }

      final result = await remoteDataSource.uploadFile(
        submissionId: submissionId,
        filePath: filePath,
        fileName: fileName,
      );
      // Fix 1: Cache uploaded file locally for immediate visibility
      unawaited(localDataSource.cacheSubmissionFile(submissionId, result));
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
        // Fix 5: Soft-delete locally so file disappears from UI immediately
        await localDataSource.softDeleteSubmissionFile(fileId);
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
        final cached = await localDataSource.getCachedSubmission(submissionId);
        final assignmentId = cached?.assignmentId ?? '';
        await localDataSource.submitAssignmentLocally(
          submissionId: submissionId,
          assignmentId: assignmentId,
        );
        // No direct syncQueue.enqueue — submitAssignmentLocally already enqueues atomically

        // Read the freshly-updated cached row for a complete response
        final updated = await localDataSource.getCachedSubmission(submissionId);
        if (updated != null) return Right(updated);
        return Right(AssignmentSubmission(
          id: submissionId,
          assignmentId: assignmentId,
          studentId: '',
          studentName: '',
          status: 'submitted',
          isLate: false,
          files: const [],
          textContent: null,
          score: null,
          feedback: null,
          submittedAt: DateTime.now(),
          gradedAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          needsSync: true,
          cachedAt: DateTime.now(),
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
            studentUsername: '', // Not available from detail response
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
      // Pass empty fileName to let datasource look it up from submission_files table
      await localDataSource.cacheFileBytes(fileId, '', result);
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
  ResultFuture<StudentAssignmentStatus?> getStudentAssignmentSubmission({
    required String assignmentId,
    required String studentId,
  }) async {
    try {
      final record = await localDataSource
          .getStudentSubmissionForAssignment(assignmentId, studentId);
      if (record == null) return const Right(null);
      return Right(StudentAssignmentStatus(
        submissionId: record.$1,
        status: record.$2,
        score: record.$3,
      ));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
