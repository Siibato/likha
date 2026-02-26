import 'dart:async';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/validation/services/validation_service.dart';
import 'package:likha/core/network/connectivity_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/datasources/local/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignment_remote_datasource.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/entities/submission_file.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';
import 'package:uuid/uuid.dart';

class AssignmentRepositoryImpl implements AssignmentRepository {
  final AssignmentRemoteDataSource _remoteDataSource;
  final AssignmentLocalDataSource _localDataSource;
  final ValidationService _validationService;
  final ConnectivityService _connectivityService;
  final SyncQueue _syncQueue;

  AssignmentRepositoryImpl({
    required AssignmentRemoteDataSource remoteDataSource,
    required AssignmentLocalDataSource localDataSource,
    required ValidationService validationService,
    required ConnectivityService connectivityService,
    required SyncQueue syncQueue,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _validationService = validationService,
        _connectivityService = connectivityService,
        _syncQueue = syncQueue;

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
      // Check connectivity
      if (!_connectivityService.isOnline) {
        // Offline: queue the mutation
        final entry = SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assignment,
          operation: SyncOperation.create,
          payload: {
            'class_id': classId,
            'title': title,
            'instructions': instructions,
            'total_points': totalPoints,
            'submission_type': submissionType,
            if (allowedFileTypes != null) 'allowed_file_types': allowedFileTypes,
            if (maxFileSizeMb != null) 'max_file_size_mb': maxFileSizeMb,
            'due_at': dueAt,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        await _syncQueue.enqueue(entry);

        // Return optimistic response
        return Right(Assignment(
          id: '',
          classId: classId,
          title: title,
          instructions: instructions,
          totalPoints: totalPoints,
          submissionType: submissionType,
          allowedFileTypes: allowedFileTypes,
          maxFileSizeMb: maxFileSizeMb,
          dueAt: DateTime.parse(dueAt),
          isPublished: false,
          submissionCount: 0,
          gradedCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      // Online: send to server
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
      // Check connectivity
      if (!_connectivityService.isOnline) {
        // Offline: queue the mutation
        final entry = SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assignment,
          operation: SyncOperation.update,
          payload: {
            'id': assignmentId,
            if (title != null) 'title': title,
            if (instructions != null) 'instructions': instructions,
            if (totalPoints != null) 'total_points': totalPoints,
            if (submissionType != null) 'submission_type': submissionType,
            if (allowedFileTypes != null) 'allowed_file_types': allowedFileTypes,
            if (maxFileSizeMb != null) 'max_file_size_mb': maxFileSizeMb,
            if (dueAt != null) 'due_at': dueAt,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        await _syncQueue.enqueue(entry);

        return Right(Assignment(
          id: assignmentId,
          classId: '',
          title: title ?? '',
          instructions: instructions ?? '',
          totalPoints: totalPoints ?? 0,
          submissionType: submissionType ?? '',
          allowedFileTypes: allowedFileTypes,
          maxFileSizeMb: maxFileSizeMb,
          dueAt: dueAt != null ? DateTime.parse(dueAt) : DateTime.now(),
          isPublished: false,
          submissionCount: 0,
          gradedCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (instructions != null) data['instructions'] = instructions;
      if (totalPoints != null) data['total_points'] = totalPoints;
      if (submissionType != null) data['submission_type'] = submissionType;
      if (allowedFileTypes != null) data['allowed_file_types'] = allowedFileTypes;
      if (maxFileSizeMb != null) data['max_file_size_mb'] = maxFileSizeMb;
      if (dueAt != null) data['due_at'] = dueAt;

      final result = await _remoteDataSource.updateAssignment(
        assignmentId: assignmentId,
        data: data,
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
      // Check connectivity
      if (!_connectivityService.isOnline) {
        // Offline: queue the mutation
        final entry = SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assignment,
          operation: SyncOperation.delete,
          payload: {
            'id': assignmentId,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        await _syncQueue.enqueue(entry);
        return const Right(null);
      }

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
      // Check connectivity
      if (!_connectivityService.isOnline) {
        // Offline: queue the mutation
        final entry = SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assignment,
          operation: SyncOperation.publish,
          payload: {
            'id': assignmentId,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        await _syncQueue.enqueue(entry);

        return Right(Assignment(
          id: assignmentId,
          classId: '',
          title: '',
          instructions: '',
          totalPoints: 0,
          submissionType: '',
          allowedFileTypes: null,
          maxFileSizeMb: null,
          dueAt: DateTime.now(),
          isPublished: true,
          submissionCount: 0,
          gradedCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

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
      // Check connectivity
      if (!_connectivityService.isOnline) {
        // Offline: queue the mutation
        final entry = SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assignmentSubmission,
          operation: SyncOperation.grade,
          payload: {
            'id': submissionId,
            'score': score,
            if (feedback != null) 'feedback': feedback,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        await _syncQueue.enqueue(entry);

        return Right(AssignmentSubmission(
          id: submissionId,
          assignmentId: '',
          studentId: '',
          studentName: '',
          status: 'graded',
          textContent: null,
          score: score,
          feedback: feedback,
          isLate: false,
          files: const [],
          submittedAt: DateTime.now(),
          gradedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

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
      // Check connectivity
      if (!_connectivityService.isOnline) {
        // Offline: queue the mutation
        final entry = SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.assignmentSubmission,
          operation: SyncOperation.update,
          payload: {
            'id': submissionId,
            'action': 'return',
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        await _syncQueue.enqueue(entry);

        return Right(AssignmentSubmission(
          id: submissionId,
          assignmentId: '',
          studentId: '',
          studentName: '',
          status: 'returned',
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
      // Check connectivity
      if (!_connectivityService.isOnline) {
        // Offline: queue the mutation
        final entry = SyncQueueEntry(
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
        );

        await _syncQueue.enqueue(entry);

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
      if (!_connectivityService.isOnline) {
        // Stage file for upload when connectivity returns
        final fileSize = await _fileSize(filePath);
        final mimeType = _mimeType(filePath);
        await _localDataSource.stageFileForUpload(
          submissionId: submissionId,
          fileName: fileName,
          fileType: mimeType,
          fileSize: fileSize,
          localPath: filePath,
        );

        return Right(SubmissionFile(
          id:         '',
          fileName:   fileName,
          fileType:   mimeType,
          fileSize:   fileSize,
          uploadedAt: DateTime.now(),
        ));
      }

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
      if (!_connectivityService.isOnline) {
        // Queue delete — file will be removed from server when online
        await _syncQueue.enqueue(SyncQueueEntry(
          id:          const Uuid().v4(),
          entityType:  SyncEntityType.submissionFile,
          operation:   SyncOperation.delete,
          payload:     {'file_id': fileId},
          status:      SyncStatus.pending,
          retryCount:  0,
          maxRetries:  5,
          createdAt:   DateTime.now(),
        ));
        return const Right(null);
      }

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
      // Check connectivity
      if (!_connectivityService.isOnline) {
        // Offline: queue the mutation
        final entry = SyncQueueEntry(
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
        );

        await _syncQueue.enqueue(entry);

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

  /// Get MIME type from file extension
  String _mimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'ppt':
      case 'pptx':
        return 'application/vnd.ms-powerpoint';
      case 'txt':
        return 'text/plain';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get file size in bytes
  Future<int> _fileSize(String filePath) async {
    try {
      final file = File(filePath);
      return await file.length();
    } catch (e) {
      return 0;
    }
  }
}
