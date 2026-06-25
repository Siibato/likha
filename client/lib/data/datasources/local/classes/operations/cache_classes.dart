import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/classes/class_model.dart';

Future<void> cacheClasses(
  LocalDatabase localDatabase,
  List<ClassModel> classes,
) async {
  try {
    final db = await localDatabase.database;
    await db.transaction((txn) async {
      for (final classModel in classes) {
        final map = classModel.toMap();
        map[CommonCols.cachedAt] = DateTime.now().toIso8601String();

        // Always recalculate student_count from local participants.
        // Server counts are unreliable when local enrollments/removals
        // exist (pending or already synced).
        final countResult = await txn.rawQuery(
          'SELECT COUNT(*) as count FROM ${DbTables.classParticipants} WHERE ${ClassParticipantsCols.classId} = ? AND ${ClassParticipantsCols.removedAt} IS NULL',
          [classModel.id],
        );
        final localCount = (countResult.first['count'] as int?) ?? 0;
        map[ClassesCols.studentCount] = localCount;

        // If the class row has pending mutations, preserve that status
        // so downstream consumers know not to overwrite it.
        final pendingRow = await txn.query(
          DbTables.classes,
          columns: [CommonCols.syncStatus],
          where: '${CommonCols.id} = ? AND ${CommonCols.syncStatus} = ?',
          whereArgs: [classModel.id, 'pending'],
          limit: 1,
        );
        if (pendingRow.isNotEmpty) {
          map[CommonCols.syncStatus] = 'pending';
        } else {
          map[CommonCols.syncStatus] = 'synced';
        }

        // Use UPDATE-or-INSERT instead of REPLACE to avoid triggering
        // ON DELETE CASCADE on class_participants.
        final existingClass = await txn.query(
          DbTables.classes,
          columns: [CommonCols.id],
          where: '${CommonCols.id} = ?',
          whereArgs: [classModel.id],
          limit: 1,
        );
        if (existingClass.isNotEmpty) {
          await txn.update(DbTables.classes, map, where: '${CommonCols.id} = ?', whereArgs: [classModel.id]);
        } else {
          await txn.insert(DbTables.classes, map);
        }
      }
    });
  } catch (e) {
    throw CacheException('Failed to cache classes: $e');
  }
}
