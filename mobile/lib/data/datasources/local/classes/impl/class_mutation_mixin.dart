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
        map['cached_at'] = now.toIso8601String();
        map['sync_status'] = 'pending';
        map['is_offline_mutation'] = 1;
        await txn.insert('classes', map);

        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.classEntity,
          operation: SyncOperation.create,
          payload: {'id': id, 'title': title, 'description': description},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
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
          'classes',
          {
            'title': title,
            'description': description,
            'updated_at': now.toIso8601String(),
            'is_offline_mutation': 1,
            'sync_status': 'pending',
            'cached_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [classId],
        );
        await syncQueue.enqueue(SyncQueueEntry(
          id: const Uuid().v4(),
          entityType: SyncEntityType.classEntity,
          operation: SyncOperation.update,
          payload: {'id': classId, 'title': title, 'description': description},
          status: SyncStatus.pending,
          retryCount: 0,
          maxRetries: 5,
          createdAt: now,
        ), txn: txn);
      });
    } catch (e) {
      throw CacheException('Failed to update class locally: $e');
    }
  }
}