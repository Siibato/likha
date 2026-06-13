import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/data/datasources/remote/tos/tos_remote_datasource.dart';
import 'package:likha/data/models/tos/tos_model.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';

ResultFuture<TableOfSpecifications> createTos(
  ServerReachabilityService serverReachabilityService,
  TosLocalDataSource localDataSource,
  TosRemoteDataSource remoteDataSource,
  SyncQueue syncQueue, {
  required String classId,
  required Map<String, dynamic> data,
}) async {
  try {
    if (serverReachabilityService.isServerReachable) {
      // Online: call server directly so the TOS exists on the server immediately
      final serverTos = await remoteDataSource.createTos(
        classId: classId,
        data: data,
      );
      await localDataSource.saveTos(serverTos);
      return Right(serverTos);
    }

    // Offline: optimistic local create + sync queue
    final now = DateTime.now();
    final id = const Uuid().v4();

    final model = TosModel(
      id: id,
      classId: classId,
      gradingPeriodNumber: (data['grading_period_number'] as num?)?.toInt() ?? (data['quarter'] as num).toInt(),
      title: data['title'] as String,
      classificationMode: data['classification_mode'] as String,
      totalItems: (data['total_items'] as num).toInt(),
      timeUnit: data['time_unit'] as String? ?? 'days',
      easyPercentage: (data['easy_percentage'] as num?)?.toDouble() ?? 50.0,
      mediumPercentage: (data['medium_percentage'] as num?)?.toDouble() ?? 30.0,
      hardPercentage: (data['hard_percentage'] as num?)?.toDouble() ?? 20.0,
      createdAt: now,
      updatedAt: now,
    );

    await localDataSource.saveTos(model);

    await syncQueue.enqueue(SyncQueueEntry(
      id: const Uuid().v4(),
      entityType: SyncEntityType.tableOfSpecifications,
      operation: SyncOperation.create,
      payload: {
        'id': id,
        'class_id': classId,
        ...data,
      },
      status: SyncStatus.pending,
      retryCount: 0,
      maxRetries: 3,
      createdAt: DateTime.now(),
    ));

    return Right(model);
  } catch (e) {
    return Left(CacheFailure(e.toString()));
  }
}
