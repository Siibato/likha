import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/data/datasources/remote/tos_remote_datasource.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';

abstract class TosRepositoryBase extends TosRepository {
  final TosRemoteDataSource remoteDataSource;
  final TosLocalDataSource localDataSource;
  final ServerReachabilityService serverReachabilityService;
  final SyncQueue syncQueue;

  TosRepositoryBase({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.serverReachabilityService,
    required this.syncQueue,
  });
}
