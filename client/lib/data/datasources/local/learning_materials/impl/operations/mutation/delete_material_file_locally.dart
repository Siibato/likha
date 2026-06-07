import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/db_schema.dart';

Future<void> deleteMaterialFileLocallyOp(
  LocalDatabase localDatabase,
  String fileId,
) async {
  try {
    final db = await localDatabase.database;
    await db.update(
      DbTables.materialFiles,
      {CommonCols.deletedAt: DateTime.now().toIso8601String()},
      where: '${CommonCols.id} = ?',
      whereArgs: [fileId],
    );
  } catch (e) {
    throw CacheException('Failed to delete material file locally: $e');
  }
}
