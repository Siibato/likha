import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/classes/class_model.dart';
import 'package:uuid/uuid.dart';
import '../class_local_datasource_base.dart';

mixin ClassMutationMixin on ClassLocalDataSourceBase {
  @override
  Future<ClassModel> createClassLocally({
    required String title,
    required String description,
    required String teacherId,
    required String teacherUsername,
    required String teacherFullName,
  }) async {
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
        createdAt: now,
        updatedAt: now,
      );

      await db.transaction((txn) async {
        final map = classModel.toMap();
        map[CommonCols.cachedAt] = now.toIso8601String();
        map[CommonCols.needsSync] = 1;
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

  @override
  Future<void> updateClassLocally({
    required String classId,
    required String title,
    required String description,
  }) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now();
      await db.transaction((txn) async {
        await txn.update(
          DbTables.classes,
          {
            ClassesCols.title: title,
            ClassesCols.description: description,
            CommonCols.updatedAt: now.toIso8601String(),
            CommonCols.needsSync: 1,
            CommonCols.cachedAt: now.toIso8601String(),
          },
          where: '${CommonCols.id} = ?',
          whereArgs: [classId],
        );
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.classEntity,
          operation: SyncOperation.update,
          payload: {'id': classId, 'title': title, 'description': description},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now,
        ), txn: txn);
      });
    } catch (e) {
      throw CacheException('Failed to update class locally: $e');
    }
  }
}
