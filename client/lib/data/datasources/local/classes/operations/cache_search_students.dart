import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/auth/user_model.dart';

Future<void> cacheSearchStudents(
  LocalDatabase localDatabase,
  List<UserModel> students,
) async {
  try {
    final db = await localDatabase.database;
    await db.transaction((txn) async {
      for (final student in students) {
        // UPDATE-or-INSERT to avoid REPLACE triggering ON DELETE CASCADE
        // on class_participants via the users table FK.
        final existingUser = await txn.query(
          DbTables.users,
          columns: [CommonCols.id],
          where: '${CommonCols.id} = ?',
          whereArgs: [student.id],
          limit: 1,
        );

        if (existingUser.isNotEmpty) {
          await txn.update(
            DbTables.users,
            {
              UsersCols.username: student.username,
              UsersCols.firstName: student.firstName,
              UsersCols.lastName: student.lastName,
              UsersCols.role: student.role,
              UsersCols.accountStatus: student.accountStatus,
              UsersCols.activatedAt: student.activatedAt?.toIso8601String(),
              CommonCols.updatedAt: DateTime.now().toIso8601String(),
              CommonCols.deletedAt: student.deletedAt?.toIso8601String(),
              CommonCols.cachedAt: DateTime.now().toIso8601String(),
              CommonCols.syncStatus: 'synced',
            },
            where: '${CommonCols.id} = ?',
            whereArgs: [student.id],
          );
        } else {
          await txn.insert(
            DbTables.users,
            {
              CommonCols.id: student.id,
              UsersCols.username: student.username,
              UsersCols.firstName: student.firstName,
              UsersCols.lastName: student.lastName,
              UsersCols.role: student.role,
              UsersCols.accountStatus: student.accountStatus,
              UsersCols.activatedAt: student.activatedAt?.toIso8601String(),
              CommonCols.createdAt: student.createdAt.toIso8601String(),
              CommonCols.updatedAt: DateTime.now().toIso8601String(),
              CommonCols.deletedAt: student.deletedAt?.toIso8601String(),
              CommonCols.cachedAt: DateTime.now().toIso8601String(),
              CommonCols.syncStatus: 'synced',
            },
          );
        }
      }
    });
  } catch (e) {
    throw CacheException('Failed to cache search students: $e');
  }
}
