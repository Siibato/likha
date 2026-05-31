import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';

Future<void> reconcileDeletedMaterialsOp(
  LocalDatabase localDatabase,
  String classId,
  List<String> activeIds,
) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now().toIso8601String();

    if (activeIds.isEmpty) {
      // Soft-delete all active materials for this class
      await db.update(
        'learning_materials',
        {'deleted_at': now},
        where: 'class_id = ? AND deleted_at IS NULL',
        whereArgs: [classId],
      );
    } else {
      // Soft-delete materials not in activeIds
      final placeholders = activeIds.map((_) => '?').join(', ');
      await db.rawUpdate(
        'UPDATE learning_materials SET deleted_at = ? WHERE class_id = ? AND deleted_at IS NULL AND id NOT IN ($placeholders)',
        [now, classId, ...activeIds],
      );
    }
  } catch (e) {
    throw CacheException('Failed to reconcile deleted materials: $e');
  }
}
