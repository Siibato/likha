import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/classes/class_remote_datasource.dart';
import 'package:uuid/uuid.dart';

ResultVoid removeStudent(
  ServerReachabilityService serverReachabilityService,
  ClassLocalDataSource localDataSource,
  ClassRemoteDataSource remoteDataSource,
  SyncQueue syncQueue, {
  required String classId,
  required String studentId,
}) async {
  try {
    if (!serverReachabilityService.isServerReachable) {
      return _removeStudentOffline(localDataSource, syncQueue, classId, studentId);
    }

    await remoteDataSource.removeStudent(
      classId: classId,
      studentId: studentId,
    );

    return const Right(null);
  } on NetworkException {
    // Server was thought reachable but API failed → fall back to offline queue
    return _removeStudentOffline(localDataSource, syncQueue, classId, studentId);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}

Future<Right<Failure, void>> _removeStudentOffline(
  ClassLocalDataSource localDataSource,
  SyncQueue syncQueue,
  String classId,
  String studentId,
) async {
  try {
    await localDataSource.removeStudentLocally(
      classId: classId,
      studentId: studentId,
    );
  } catch (_) {}

  await syncQueue.enqueue(SyncQueueEntry(
    id: const Uuid().v4(),
    entityType: SyncEntityType.classEntity,
    operation: SyncOperation.removeEnrollment,
    payload: {'class_id': classId, 'student_id': studentId},
    status: SyncStatus.pending,
    retryCount: 0,
    maxRetries: 5,
    createdAt: DateTime.now(),
  ));

  try {
    await localDataSource.getCachedClassDetail(classId);
  } catch (_) {
    // Non-critical
  }

  return const Right(null);
}
