import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';

Future<void> clearAllCacheOp(LocalDatabase localDatabase) async {
  try {
    final db = await localDatabase.database;
    await db.delete('learning_materials');
    await db.delete('material_files');
  } catch (e) {
    throw CacheException('Failed to clear learning materials cache: $e');
  }
}
