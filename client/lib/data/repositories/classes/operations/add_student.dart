import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/classes/class_remote_datasource.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:uuid/uuid.dart';

ResultFuture<Participant> addStudent(
  ServerReachabilityService serverReachabilityService,
  ClassLocalDataSource localDataSource,
  ClassRemoteDataSource remoteDataSource,
  SyncQueue syncQueue, {
  required String classId,
  required String studentId,
}) async {
  try {
    if (!serverReachabilityService.isServerReachable) {
      return _addStudentOffline(localDataSource, syncQueue, classId, studentId);
    }

    final result = await remoteDataSource.addStudent(
      classId: classId,
      studentId: studentId,
    );

    return Right(result);
  } on NetworkException {
    // Server was thought reachable but API failed → fall back to offline queue
    return _addStudentOffline(localDataSource, syncQueue, classId, studentId);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}

Future<Right<Failure, Participant>> _addStudentOffline(
  ClassLocalDataSource localDataSource,
  SyncQueue syncQueue,
  String classId,
  String studentId,
) async {
  // Prevent duplicate queue entries
  try {
    final alreadyParticipating = await localDataSource.getParticipantIds(classId);
    if (alreadyParticipating.contains(studentId)) {
      final cachedStudent = await localDataSource.getStudentById(studentId);
      final s = cachedStudent ?? _skeletonStudent(studentId);
      return Right(Participant(id: '', student: s, joinedAt: DateTime.now()));
    }
  } catch (_) {}

  UserModel? cachedStudent;
  try {
    cachedStudent = await localDataSource.getStudentById(studentId);
  } catch (_) {}

  final studentModel = cachedStudent ?? _skeletonStudent(studentId);

  String? participantId;
  try {
    participantId = await localDataSource.addStudentLocally(
      classId: classId,
      student: studentModel,
    );
  } catch (_) {}

  await syncQueue.enqueue(SyncQueueEntry(
    id: const Uuid().v4(),
    entityType: SyncEntityType.classEntity,
    operation: SyncOperation.addEnrollment,
    payload: {
      'class_id': classId,
      'student_id': studentId,
      if (cachedStudent != null) 'student_username': cachedStudent.username,
      if (cachedStudent != null) 'student_full_name': cachedStudent.fullName,
      if (participantId != null) 'local_enrollment_id': participantId,
    },
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

  return Right(Participant(id: '', student: studentModel, joinedAt: DateTime.now()));
}

UserModel _skeletonStudent(String studentId) => UserModel(
  id: studentId,
  username: '',
  fullName: '',
  role: 'student',
  accountStatus: 'active',
  isActive: true,
  activatedAt: null,
  createdAt: DateTime.now(),
);
