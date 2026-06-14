import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/classes/class_model.dart';
import 'package:uuid/uuid.dart';

Future<ClassModel> createClassLocally(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String title,
  String description,
  String teacherId,
  String teacherUsername,
  String teacherFullName,
) async {
  try {
    final db = await localDatabase.database;
    final id = const Uuid().v4();
    final now = DateTime.now();
    final classModel = ClassModel(
      id: id,
      title: title,
      description: description,
      teacherId: teacherId,
      teacherUsername: teacherUsername,
      teacherFullName: teacherFullName,
      isArchived: false,
      studentCount: 0,
      gradingPeriodType: 'quarter',
      createdAt: now,
      updatedAt: now,
    );

    await db.transaction((txn) async {
      final map = classModel.toMap();
      map[CommonCols.cachedAt] = now.toIso8601String();
      map[CommonCols.syncStatus] = 'pending';
      await txn.insert(DbTables.classes, map);

      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.classEntity,
        operation: SyncOperation.create,
        payload: {
          'id': id,
          'title': title,
          'description': description,
          'teacher_id': teacherId,
          'teacher_username': teacherUsername,
          'teacher_full_name': teacherFullName,
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });

    return classModel;
  } catch (e) {
    throw CacheException('Failed to create class locally: $e');
  }
}
