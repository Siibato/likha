import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/remote/learning_materials/learning_material_remote_datasource.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/entities/material_detail.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';
import 'operations/learning_materials.dart' as ops;

class LearningMaterialRepositoryImpl implements LearningMaterialRepository {
  final LearningMaterialRemoteDataSource _remoteDataSource;
  final LearningMaterialLocalDataSource _localDataSource;
  final SyncQueue _syncQueue;
  final DataEventBus _dataEventBus;

  LearningMaterialRepositoryImpl({
    required LearningMaterialRemoteDataSource remoteDataSource,
    required LearningMaterialLocalDataSource localDataSource,
    required SyncQueue syncQueue,
    required DataEventBus dataEventBus,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _syncQueue = syncQueue,
        _dataEventBus = dataEventBus;

  @override
  ResultFuture<MutationResult<LearningMaterial>> createMaterial({
    required String classId,
    required String title,
    String? description,
    String? contentText,
  }) =>
      ops.createMaterial(
        _localDataSource,
        _syncQueue,
        _remoteDataSource,
        classId: classId,
        title: title,
        description: description,
        contentText: contentText,
      );

  @override
  ResultFuture<MutationResult<LearningMaterial>> updateMaterial({
    required String materialId,
    String? title,
    String? description,
    String? contentText,
  }) =>
      ops.updateMaterial(
        _localDataSource,
        _syncQueue,
        _remoteDataSource,
        materialId: materialId,
        title: title,
        description: description,
        contentText: contentText,
      );

  @override
  ResultFuture<MutationResult<void>> deleteMaterial({required String materialId}) =>
      ops.deleteMaterial(
        _localDataSource,
        _syncQueue,
        _remoteDataSource,
        materialId: materialId,
      );

  @override
  ResultFuture<MutationResult<LearningMaterial>> reorderMaterial({
    required String materialId,
    required int newOrderIndex,
  }) =>
      ops.reorderMaterial(
        _localDataSource,
        _syncQueue,
        _remoteDataSource,
        materialId: materialId,
        newOrderIndex: newOrderIndex,
      );

  @override
  ResultFuture<MutationResult<void>> reorderAllMaterials({
    required String classId,
    required List<String> materialIds,
  }) =>
      ops.reorderAllMaterials(
        _localDataSource,
        _syncQueue,
        _remoteDataSource,
        classId: classId,
        materialIds: materialIds,
      );

  @override
  ResultFuture<List<LearningMaterial>> getMaterials({required String classId}) =>
      ops.getMaterials(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        classId: classId,
      );

  @override
  ResultFuture<MaterialDetail> getMaterialDetail({required String materialId, bool skipBackgroundRefresh = false}) =>
      ops.getMaterialDetail(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        materialId: materialId,
        skipBackgroundRefresh: skipBackgroundRefresh,
      );

  @override
  ResultFuture<MutationResult<MaterialFile>> uploadFile({
    required String materialId,
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onSendProgress,
  }) =>
      ops.uploadFile(
        _localDataSource,
        _syncQueue,
        _remoteDataSource,
        materialId: materialId,
        filePath: filePath,
        fileName: fileName,
        onSendProgress: onSendProgress,
      );

  @override
  ResultFuture<MutationResult<void>> deleteFile({required String fileId}) =>
      ops.deleteFile(
        _localDataSource,
        _syncQueue,
        _remoteDataSource,
        fileId: fileId,
      );

  @override
  ResultFuture<List<int>> downloadFile({required String fileId}) =>
      ops.downloadFile(
        _localDataSource,
        _remoteDataSource,
        fileId: fileId,
      );
}