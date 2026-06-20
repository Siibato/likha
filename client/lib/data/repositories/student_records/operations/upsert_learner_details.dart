import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/student_records/student_records_local_datasource.dart';
import 'package:likha/data/models/student_records/learner_details_model.dart';
import 'package:likha/domain/student_records/entities/learner_details.dart';
import 'package:uuid/uuid.dart';

ResultFuture<LearnerDetails> upsertLearnerDetails(
  StudentRecordsLocalDataSource localDataSource,
  SyncQueue syncQueue, {
  required String classId,
  required String studentId,
  required Map<String, dynamic> data,
}) async {
  try {
    final entityId = data['id'] as String? ?? const Uuid().v4();
    final queueEntryId = const Uuid().v4();
    final now = DateTime.now();

    final model = LearnerDetailsModel(
      id: entityId,
      userId: studentId,
      lrn: data['lrn'] as String?,
      age: data['age'] as int?,
      sex: data['sex'] as String?,
      trackStrand: data['track_strand'] as String?,
      curriculum: data['curriculum'] as String?,
      birthdate: data['birthdate'] as String?,
      birthplace: data['birthplace'] as String?,
      homeAddress: data['home_address'] as String?,
      fatherName: data['father_name'] as String?,
      fatherContact: data['father_contact'] as String?,
      motherName: data['mother_name'] as String?,
      motherContact: data['mother_contact'] as String?,
      guardianName: data['guardian_name'] as String?,
      guardianContact: data['guardian_contact'] as String?,
      dateAdmitted: data['date_admitted'] as String?,
    );

    final payload = {
      ...model.toJson(),
      'class_id': classId,
      'student_id': studentId,
    };

    final db = await localDataSource.localDatabase.database;
    await db.transaction((txn) async {
      await localDataSource.insertLearnerDetails(model, txn: txn);
      await syncQueue.enqueue(
        SyncQueueEntry(
          id: queueEntryId,
          entityType: SyncEntityType.learnerDetails,
          operation: SyncOperation.create,
          payload: payload,
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ),
        txn: txn,
      );
    });

    return Right(model);
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
