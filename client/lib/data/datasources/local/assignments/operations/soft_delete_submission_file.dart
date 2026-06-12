import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';

Future<void> softDeleteSubmissionFile(
  LocalDatabase localDatabase,
  String fileId,
) async {
  try {
    final db = await localDatabase.database;
    await db.delete(
      DbTables.submissionFiles,
      where: '${CommonCols.id} = ?',
      whereArgs: [fileId],
    );
  } catch (e) {
    throw CacheException('Failed to delete submission file: $e');
  }
}
