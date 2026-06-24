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

    // Identify participants with pending local mutations to avoid clobbering
    final pendingRows = await db.query(
      DbTables.classParticipants,
      columns: [ClassParticipantsCols.userId],
      where: '${ClassParticipantsCols.classId} = ? AND ${CommonCols.syncStatus} = ?',
      whereArgs: [classId, 'pending'],
    );
    final pendingUserIds = pendingRows
        .map((r) => r[ClassParticipantsCols.userId] as String?)
        .whereType<String>()
        .toSet();

    await db.transaction((txn) async {
      for (final user in participants) {
        // Skip participants that have pending local mutations
        if (pendingUserIds.contains(user.id)) continue;

        // Upsert user into users table without REPLACE to avoid
        // triggering ON DELETE CASCADE on class_participants.
        final existingUser = await txn.query(
          DbTables.users,
          columns: [CommonCols.id],
          where: '${CommonCols.id} = ?',
          whereArgs: [user.id],
          limit: 1,
        );

        if (existingUser.isNotEmpty) {
          await txn.update(
            DbTables.users,
            {
              UsersCols.username: user.username,
              UsersCols.firstName: user.firstName,
              UsersCols.lastName: user.lastName,
              UsersCols.role: user.role,
              UsersCols.accountStatus: user.accountStatus,
              UsersCols.activatedAt: user.activatedAt?.toIso8601String(),
              CommonCols.updatedAt: now.toIso8601String(),
              CommonCols.cachedAt: now.toIso8601String(),
              CommonCols.syncStatus: 'synced',
            },
            where: '${CommonCols.id} = ?',
            whereArgs: [user.id],
          );
        } else {
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
          );
        }

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
