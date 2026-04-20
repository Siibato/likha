import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/tos/tos_model.dart';
import '../tos_local_datasource_base.dart';

mixin TosMutationMixin on TosLocalDataSourceBase {
  @override
  Future<void> saveTos(TosModel tos) async {
    final db = await localDatabase.database;
    final now = DateTime.now();
    await db.transaction((txn) async {
      await txn.insert(
        DbTables.tableOfSpecifications,
        {
          ...tos.toMap(),
          CommonCols.needsSync: 1,
          CommonCols.cachedAt: now.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.tableOfSpecifications,
        operation: SyncOperation.create,
        payload: tos.toMap(),
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });
  }

  @override
  Future<void> updateTosFields(
    String tosId,
    Map<String, dynamic> data,
  ) async {
    final db = await localDatabase.database;
    final now = DateTime.now();
    await db.transaction((txn) async {
      await txn.update(
        DbTables.tableOfSpecifications,
        {
          ...data,
          CommonCols.updatedAt: now.toIso8601String(),
          CommonCols.needsSync: 1,
          CommonCols.cachedAt: now.toIso8601String(),
        },
        where: '${CommonCols.id} = ?',
        whereArgs: [tosId],
      );
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.tableOfSpecifications,
        operation: SyncOperation.update,
        payload: {'id': tosId, ...data},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });
  }

  @override
  Future<void> softDeleteTos(String tosId) async {
    final db = await localDatabase.database;
    final now = DateTime.now();
    await db.transaction((txn) async {
      await txn.update(
        DbTables.tableOfSpecifications,
        {
          CommonCols.deletedAt: now.toIso8601String(),
          CommonCols.updatedAt: now.toIso8601String(),
          CommonCols.needsSync: 1,
          CommonCols.cachedAt: now.toIso8601String(),
        },
        where: '${CommonCols.id} = ?',
        whereArgs: [tosId],
      );
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.tableOfSpecifications,
        operation: SyncOperation.delete,
        payload: {'id': tosId},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });
  }

  @override
  Future<void> saveCompetency(CompetencyModel competency) async {
    final db = await localDatabase.database;
    final now = DateTime.now();
    await db.transaction((txn) async {
      await txn.insert(
        DbTables.tosCompetencies,
        {
          ...competency.toMap(),
          CommonCols.needsSync: 1,
          CommonCols.cachedAt: now.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.tosCompetency,
        operation: SyncOperation.create,
        payload: competency.toMap(),
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });
  }

  @override
  Future<void> updateCompetencyFields(
    String competencyId,
    Map<String, dynamic> data,
  ) async {
    final db = await localDatabase.database;
    final now = DateTime.now();
    // Map API/UI key names to the local SQLite column names.
    final localData = {
      for (final e in data.entries)
        (e.key == 'days_taught' ? 'time_units_taught' : e.key): e.value,
    };
    await db.transaction((txn) async {
      await txn.update(
        DbTables.tosCompetencies,
        {
          ...localData,
          CommonCols.updatedAt: now.toIso8601String(),
          CommonCols.needsSync: 1,
          CommonCols.cachedAt: now.toIso8601String(),
        },
        where: '${CommonCols.id} = ?',
        whereArgs: [competencyId],
      );
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.tosCompetency,
        operation: SyncOperation.update,
        payload: {'id': competencyId, ...data},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });
  }

  @override
  Future<void> softDeleteCompetency(String competencyId) async {
    final db = await localDatabase.database;
    final now = DateTime.now();
    await db.transaction((txn) async {
      await txn.update(
        DbTables.tosCompetencies,
        {
          CommonCols.deletedAt: now.toIso8601String(),
          CommonCols.updatedAt: now.toIso8601String(),
          CommonCols.needsSync: 1,
          CommonCols.cachedAt: now.toIso8601String(),
        },
        where: '${CommonCols.id} = ?',
        whereArgs: [competencyId],
      );
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.tosCompetency,
        operation: SyncOperation.delete,
        payload: {'id': competencyId},
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });
  }

  @override
  Future<void> bulkSaveCompetencies(List<CompetencyModel> competencies) async {
    final db = await localDatabase.database;
    final now = DateTime.now();
    await db.transaction((txn) async {
      for (final comp in competencies) {
        await txn.insert(
          DbTables.tosCompetencies,
          {
            ...comp.toMap(),
            CommonCols.needsSync: 1,
            CommonCols.cachedAt: now.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      // Enqueue a single bulk operation with all competencies
      await syncQueue.enqueue(SyncQueueEntry(
        id: const Uuid().v4(),
        entityType: SyncEntityType.tosCompetency,
        operation: SyncOperation.create,
        payload: {
          'competencies': competencies.map((c) => c.toMap()).toList(),
        },
        status: SyncStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        createdAt: now,
      ), txn: txn);
    });
  }
}
