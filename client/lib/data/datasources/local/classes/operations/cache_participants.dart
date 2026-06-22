import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> cacheParticipants(
  LocalDatabase localDatabase,
  String classId,
  List<UserModel> participants,
) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now();

    await db.transaction((txn) async {
      for (final user in participants) {
        // Upsert user into users table
        await txn.insert(
          DbTables.users,
          {
            CommonCols.id: user.id,
            UsersCols.username: user.username,
            UsersCols.firstName: user.firstName,
            UsersCols.lastName: user.lastName,
            UsersCols.role: user.role,
            UsersCols.accountStatus: user.accountStatus,
            UsersCols.activatedAt: user.activatedAt?.toIso8601String(),
            CommonCols.createdAt: user.createdAt.toIso8601String(),
            CommonCols.updatedAt: now.toIso8601String(),
            CommonCols.cachedAt: now.toIso8601String(),
            CommonCols.syncStatus: 'synced',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Upsert participation into class_participants table
        final syntheticId = 'local_${classId}_${user.id}';
        await txn.insert(
          DbTables.classParticipants,
          {
            CommonCols.id: syntheticId,
            ClassParticipantsCols.classId: classId,
            ClassParticipantsCols.userId: user.id,
            ClassParticipantsCols.joinedAt: now.toIso8601String(),
            ClassParticipantsCols.removedAt: null,
            CommonCols.updatedAt: now.toIso8601String(),
            CommonCols.cachedAt: now.toIso8601String(),
            CommonCols.syncStatus: 'synced',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  } catch (e) {
    throw CacheException('Failed to cache participants: $e');
  }
}
