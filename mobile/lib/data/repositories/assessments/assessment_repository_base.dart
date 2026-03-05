import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/network/connectivity_service.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/sync/sync_logger.dart';
import 'package:likha/core/validation/services/validation_service.dart';
import 'package:likha/services/storage_service.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessment_remote_datasource.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

abstract class AssessmentRepositoryBase extends AssessmentRepository {
  final AssessmentRemoteDataSource remoteDataSource;
  final AssessmentLocalDataSource localDataSource;
  final ValidationService validationService;
  final SyncQueue syncQueue;
  final ServerReachabilityService serverReachabilityService;
  final StorageService storageService;
  final DataEventBus dataEventBus;
  final SyncLogger syncLogger;

  AssessmentRepositoryBase({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.validationService,
    required ConnectivityService connectivityService,
    required this.syncQueue,
    required this.serverReachabilityService,
    required this.storageService,
    required this.dataEventBus,
    required this.syncLogger,
  });
}