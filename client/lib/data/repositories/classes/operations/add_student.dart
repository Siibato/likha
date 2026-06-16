import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:uuid/uuid.dart';

ResultFuture<MutationResult<Participant>> addStudent(
  ClassLocalDataSource localDataSource,
  SyncQueue syncQueue,
  {
  required String classId,
  required String studentId,
}) async {
  try {
    final now = DateTime.now();
    final queueEntryId = const Uuid().v4();
    final participantId = const Uuid().v4();

    UserModel? cachedStudent;
    try {
      cachedStudent = await localDataSource.getStudentById(studentId);
    } catch (_) {}

    final studentModel = cachedStudent ?? _skeletonStudent(studentId);

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.addStudentLocally(
        classId: classId,
        student: studentModel,
        txn: txn,
      );
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.classEntity,
          operation: SyncOperation.addEnrollment,
          payload: {
            'class_id': classId,
            'student_id': studentId,
            'local_enrollment_id': participantId,
            if (cachedStudent != null) 'student_username': cachedStudent.username,
            if (cachedStudent != null) 'student_full_name': cachedStudent.fullName,
          },
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    final participant = Participant(
      id: participantId,
      student: studentModel,
      joinedAt: now,
    );

    return Right(MutationResult(entity: participant, status: SyncStatus.pending));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
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
