import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/entity_sync_helper.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/validation/services/validation_service.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/class_remote_datasource.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';
import 'package:likha/services/storage_service.dart';

abstract class ClassRepositoryBase extends ClassRepository {
  final ClassRemoteDataSource remoteDataSource;
  final ClassLocalDataSource localDataSource;
  final ValidationService validationService;
  final ServerReachabilityService serverReachabilityService;
  final EntitySyncHelper entitySyncHelper;
  final SyncQueue syncQueue;
  final StorageService storageService;

  ClassRepositoryBase({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.validationService,
    required this.serverReachabilityService,
    required this.entitySyncHelper,
    required this.syncQueue,
    required this.storageService,
  });

  Future<String?> getCurrentUserId() async {
    try {
      return await storageService.getUserId();
    } catch (e) {
      return null;
    }
  }

  Future<void> syncInBackgroundForClass(String classId) async {
    try {
      final remoteClass = await remoteDataSource.getClassDetail(classId: classId);
      await localDataSource.cacheClassDetail(remoteClass);
    } catch (_) {
      // Best-effort
    }
  }
}