import 'dart:async';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/validation/services/validation_service.dart';
import 'package:likha/core/network/connectivity_service.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/services/storage_service.dart';
import 'package:likha/data/datasources/local/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/remote/learning_material_remote_datasource.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/entities/material_detail.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:uuid/uuid.dart';

class LearningMaterialRepositoryImpl implements LearningMaterialRepository {
  final LearningMaterialRemoteDataSource _remoteDataSource;
  final LearningMaterialLocalDataSource _localDataSource;
  final ValidationService _validationService;
  final ConnectivityService _connectivityService;
  final SyncQueue _syncQueue;
  final ServerReachabilityService _serverReachabilityService;
  final StorageService _storageService;

  LearningMaterialRepositoryImpl({
    required LearningMaterialRemoteDataSource remoteDataSource,
    required LearningMaterialLocalDataSource localDataSource,
    required ValidationService validationService,
    required ConnectivityService connectivityService,
    required SyncQueue syncQueue,
    required ServerReachabilityService serverReachabilityService,
    required StorageService storageService,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _validationService = validationService,
        _connectivityService = connectivityService,
        _syncQueue = syncQueue,
        _serverReachabilityService = serverReachabilityService,
        _storageService = storageService;

  @override
  ResultFuture<LearningMaterial> createMaterial({
    required String classId,
    required String title,
    String? description,
    String? contentText,
  }) async {
    try {
      // Check connectivity
      if (!_serverReachabilityService.isServerReachable) {
        // Offline: queue the mutation
        final entry = SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.learningMaterial,
          operation: SyncOperation.create,
          payload: {
            'class_id': classId,
            'title': title,
            if (description != null) 'description': description,
            if (contentText != null) 'content_text': contentText,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        await _syncQueue.enqueue(entry);

        // Create optimistic response
        final optimisticMaterial = LearningMaterial(
          id: '',
          classId: classId,
          title: title,
          description: description,
          contentText: contentText,
          orderIndex: 0,
          fileCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Cache the new material for offline access
        try {
          final currentCached = await _localDataSource.getCachedMaterials(classId);
          final optimisticModel = LearningMaterialModel(
            id: '',
            classId: classId,
            title: title,
            description: description,
            contentText: contentText,
            orderIndex: 0,
            fileCount: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _localDataSource.cacheMaterials([optimisticModel, ...currentCached]);
        } catch (_) {
          // If caching fails, still return the optimistic response
        }

        return Right(optimisticMaterial);
      }

      final result = await _remoteDataSource.createMaterial(
        classId: classId,
        data: {
          'title': title,
          if (description != null) 'description': description,
          if (contentText != null) 'content_text': contentText,
        },
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  ResultFuture<List<LearningMaterial>> getMaterials({required String classId}) async {
    try {
      var cachedMaterials = <LearningMaterial>[];
      bool hasCachedData = false;

      // Step 1: Try to get cached data
      try {
        cachedMaterials = await _localDataSource.getCachedMaterials(classId);
        hasCachedData = true;
      } on CacheException {
        hasCachedData = false;
      }

      // Step 2: If online, fetch fresh data
      if (_serverReachabilityService.isServerReachable) {
        try {
          final freshMaterials = await _remoteDataSource.getMaterials(classId: classId);
          await _localDataSource.cacheMaterials(freshMaterials);
          return Right(freshMaterials);
        } catch (e) {
          // Server fetch failed - fall through to cached data
          if (!hasCachedData) {
            if (e is ServerException) {
              return Left(ServerFailure(e.message));
            } else if (e is NetworkException) {
              return Left(NetworkFailure(e.message));
            }
            return Left(ServerFailure(e.toString()));
          }
          // Has cache, will use it below
        }
      }

      // Step 3: Use cached data if we have it
      if (hasCachedData) {
        return Right(cachedMaterials);
      }

      // No cache and no internet
      return Left(NetworkFailure('No internet connection and no cached data'));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<MaterialDetail> getMaterialDetail({required String materialId}) async {
    try {
      LearningMaterialModel? cachedMaterial;
      bool hasCachedData = false;

      // Step 1: Try to get cached data
      try {
        cachedMaterial = await _localDataSource.getCachedMaterialDetail(materialId);
        hasCachedData = true;
      } on CacheException {
        hasCachedData = false;
      }

      // Step 2: If online, fetch fresh data
      if (_serverReachabilityService.isServerReachable) {
        try {
          final freshMaterial = await _remoteDataSource.getMaterialDetail(materialId: materialId);

          // Convert to MaterialDetail (don't cache MaterialDetailModel as it's a different type)
          final detail = MaterialDetail(
            id: freshMaterial.id,
            classId: freshMaterial.classId,
            title: freshMaterial.title,
            description: freshMaterial.description,
            contentText: freshMaterial.contentText,
            orderIndex: freshMaterial.orderIndex,
            files: const [], // Files are stored separately in the database
            createdAt: freshMaterial.createdAt,
            updatedAt: freshMaterial.updatedAt,
          );
          return Right(detail);
        } catch (e) {
          // Server fetch failed - fall through to cached data
          if (!hasCachedData) {
            if (e is ServerException) {
              return Left(ServerFailure(e.message));
            } else if (e is NetworkException) {
              return Left(NetworkFailure(e.message));
            }
            return Left(ServerFailure(e.toString()));
          }
          // Has cache, will use it below
        }
      }

      // Step 3: Use cached data if we have it
      if (hasCachedData && cachedMaterial != null) {
        final detail = MaterialDetail(
          id: cachedMaterial.id,
          classId: cachedMaterial.classId,
          title: cachedMaterial.title,
          description: cachedMaterial.description,
          contentText: cachedMaterial.contentText,
          orderIndex: cachedMaterial.orderIndex,
          files: const [], // Files are stored separately in the database
          createdAt: cachedMaterial.createdAt,
          updatedAt: cachedMaterial.updatedAt,
        );
        return Right(detail);
      }

      // No cache and no internet
      return Left(NetworkFailure('No internet connection and no cached data'));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<LearningMaterial> updateMaterial({
    required String materialId,
    String? title,
    String? description,
    String? contentText,
  }) async {
    try {
      // Check connectivity
      if (!_serverReachabilityService.isServerReachable) {
        // Offline: queue the mutation
        final entry = SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.learningMaterial,
          operation: SyncOperation.update,
          payload: {
            'id': materialId,
            if (title != null) 'title': title,
            if (description != null) 'description': description,
            if (contentText != null) 'content_text': contentText,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        await _syncQueue.enqueue(entry);

        return Right(LearningMaterial(
          id: materialId,
          classId: '',
          title: title ?? '',
          description: description,
          contentText: contentText,
          orderIndex: 0,
          fileCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      final result = await _remoteDataSource.updateMaterial(
        materialId: materialId,
        data: {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (contentText != null) 'content_text': contentText,
        },
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  ResultVoid deleteMaterial({required String materialId}) async {
    try {
      // Check connectivity
      if (!_serverReachabilityService.isServerReachable) {
        // Offline: queue the mutation
        final entry = SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.learningMaterial,
          operation: SyncOperation.delete,
          payload: {
            'id': materialId,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        await _syncQueue.enqueue(entry);
        return const Right(null);
      }

      await _remoteDataSource.deleteMaterial(materialId: materialId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  ResultFuture<LearningMaterial> reorderMaterial({
    required String materialId,
    required int newOrderIndex,
  }) async {
    try {
      // Check connectivity
      if (!_serverReachabilityService.isServerReachable) {
        // Offline: queue the mutation
        final entry = SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.learningMaterial,
          operation: SyncOperation.update,
          payload: {
            'id': materialId,
            'order_index': newOrderIndex,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        );

        await _syncQueue.enqueue(entry);

        return Right(LearningMaterial(
          id: materialId,
          classId: '',
          title: '',
          description: null,
          contentText: null,
          orderIndex: newOrderIndex,
          fileCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      final result = await _remoteDataSource.reorderMaterial(
        materialId: materialId,
        newOrderIndex: newOrderIndex,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  ResultFuture<MaterialFile> uploadFile({
    required String materialId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      // Check connectivity
      if (!_serverReachabilityService.isServerReachable) {
        // Offline: stage file for later upload
        await _localDataSource.stageMaterialFileForUpload(
          materialId: materialId,
          fileName: fileName,
          fileType: _mimeType(filePath),
          fileSize: await _fileSize(filePath),
          localPath: filePath,
        );

        // Return optimistic response
        return Right(MaterialFile(
          id: '',
          fileName: fileName,
          fileType: _mimeType(filePath),
          fileSize: await _fileSize(filePath),
          uploadedAt: DateTime.now(),
        ));
      }

      final result = await _remoteDataSource.uploadFile(
        materialId: materialId,
        filePath: filePath,
        fileName: fileName,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
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

  @override
  ResultVoid deleteFile({required String fileId}) async {
    try {
      // Check connectivity
      if (!_serverReachabilityService.isServerReachable) {
        // Offline: queue the delete operation
        await _syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.materialFile,
          operation: SyncOperation.delete,
          payload: {'file_id': fileId},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: DateTime.now(),
        ));
        return const Right(null);
      }

      await _remoteDataSource.deleteFile(fileId: fileId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  ResultFuture<List<int>> downloadFile({required String fileId}) async {
    try {
      // Check if file is cached first
      if (await _localDataSource.isFileCached(fileId)) {
        final cachedFile = await _localDataSource.getCachedFile(fileId);
        return Right(cachedFile);
      }

      // Download from remote and cache
      final result = await _remoteDataSource.downloadFile(fileId: fileId);
      // Try to cache the file (but don't fail if caching fails)
      try {
        await _localDataSource.cacheFile(fileId, fileId, result);
      } catch (e) {
        // Ignore caching errors, still return the file
      }
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
