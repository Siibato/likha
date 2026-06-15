import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> cacheSearchStudentsOp(
  LocalDatabase localDatabase,
  List<UserModel> students,
) async {
  try {
    final db = await localDatabase.database;
    await db.transaction((txn) async {
      for (final student in students) {
        // Use ConflictAlgorithm.replace to update existing student data
        // This ensures stale data from prior sync/searches is updated
        await txn.insert(
          DbTables.users,
          {
            CommonCols.id: student.id,
            UsersCols.username: student.username,
            UsersCols.fullName: student.fullName,
            UsersCols.role: student.role,
            UsersCols.accountStatus: student.accountStatus,
            UsersCols.activatedAt: student.activatedAt?.toIso8601String(),
            CommonCols.createdAt: student.createdAt.toIso8601String(),
            CommonCols.updatedAt: DateTime.now().toIso8601String(),
            CommonCols.deletedAt: student.deletedAt?.toIso8601String(),
            CommonCols.cachedAt: DateTime.now().toIso8601String(),
            CommonCols.needsSync: 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  } catch (e) {
    throw CacheException('Failed to cache search students: $e');
  }
}
