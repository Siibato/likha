import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';

Future<void> deleteAssignment(
  LocalDatabase localDatabase,
  String assignmentId,
) async {
  try {
    final db = await localDatabase.database;
    await db.update(
      DbTables.assignments,
      {CommonCols.deletedAt: DateTime.now().toIso8601String()},
      where: '${CommonCols.id} = ?',
      whereArgs: [assignmentId],
    );
  } catch (e) {
    throw CacheException('Failed to delete assignment locally: $e');
  }
}
