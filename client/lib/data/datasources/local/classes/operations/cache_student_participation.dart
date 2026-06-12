import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> cacheStudentParticipation(
  LocalDatabase localDatabase,
  String classId,
  String userId,
  DateTime joinedAt,
) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now();
    final syntheticId = 'local_${classId}_$userId';
    await db.insert(
      DbTables.classParticipants,
      {
        CommonCols.id: syntheticId,
        ClassParticipantsCols.classId: classId,
        ClassParticipantsCols.userId: userId,
        ClassParticipantsCols.joinedAt: joinedAt.toIso8601String(),
        CommonCols.updatedAt: now.toIso8601String(),
        ClassParticipantsCols.removedAt: null,
        CommonCols.cachedAt: now.toIso8601String(),
        CommonCols.needsSync: 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  } catch (e) {
    throw CacheException('Failed to cache student participation: $e');
  }
}
