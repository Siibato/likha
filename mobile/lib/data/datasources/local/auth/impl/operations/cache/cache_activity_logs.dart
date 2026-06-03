import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/security/encryption_service.dart';
import 'package:likha/data/models/auth/activity_log_model.dart';
import 'package:sqflite/sqflite.dart';

Future<void> cacheActivityLogsOp(
  LocalDatabase localDatabase,
  EncryptionService enc,
  List<ActivityLogModel> logs,
  String userId,
) async {
  try {
    final db = await localDatabase.database;
    await db.transaction((txn) async {
      for (final log in logs) {
        await txn.insert(
          'activity_logs',
          {
            'id': log.id,
            'user_id': log.userId,
            'action': log.action,
            'details': enc.encryptField(log.details),
            'created_at': log.createdAt.toIso8601String(),
            'cached_at': DateTime.now().toIso8601String(),
            'needs_sync': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  } catch (e) {
    throw CacheException('Failed to cache activity logs: $e');
  }
}
