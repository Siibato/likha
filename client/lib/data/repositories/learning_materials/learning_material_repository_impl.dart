import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/network/server_reachability_service.dart';
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
  final ServerReachabilityService _serverReachabilityService;
  final DataEventBus _dataEventBus;

  LearningMaterialRepositoryImpl({
    required LearningMaterialRemoteDataSource remoteDataSource,
    required LearningMaterialLocalDataSource localDataSource,
    required SyncQueue syncQueue,
    required ServerReachabilityService serverReachabilityService,
    required DataEventBus dataEventBus,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _syncQueue = syncQueue,
        _serverReachabilityService = serverReachabilityService,
        _dataEventBus = dataEventBus;

  @override
  ResultFuture<LearningMaterial> createMaterial({
    required String classId,
    required String title,
    String? description,
    String? contentText,
  }) =>
      ops.createMaterial(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        classId: classId,
        title: title,
        description: description,
        contentText: contentText,
      );

  @override
  ResultFuture<LearningMaterial> updateMaterial({
    required String materialId,
    String? title,
    String? description,
    String? contentText,
  }) =>
      ops.updateMaterial(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        materialId: materialId,
        title: title,
        description: description,
        contentText: contentText,
      );

  @override
  ResultVoid deleteMaterial({required String materialId}) =>
      ops.deleteMaterial(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        materialId: materialId,
      );

  @override
  ResultFuture<LearningMaterial> reorderMaterial({
    required String materialId,
    required int newOrderIndex,
  }) =>
      ops.reorderMaterial(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        materialId: materialId,
        newOrderIndex: newOrderIndex,
      );

  @override
  ResultVoid reorderAllMaterials({
    required String classId,
    required List<String> materialIds,
  }) =>
      ops.reorderAllMaterials(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
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
  ResultFuture<MaterialDetail> getMaterialDetail({required String materialId}) =>
      ops.getMaterialDetail(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        materialId: materialId,
      );

  @override
  ResultFuture<MaterialFile> uploadFile({
    required String materialId,
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onSendProgress,
  }) =>
      ops.uploadFile(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        materialId: materialId,
        filePath: filePath,
        fileName: fileName,
        onSendProgress: onSendProgress,
      );

  @override
  ResultVoid deleteFile({required String fileId}) =>
      ops.deleteFile(
        _serverReachabilityService,
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
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