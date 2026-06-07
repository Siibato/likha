import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/security/encryption_service.dart';
import 'package:likha/data/models/auth/activity_log_model.dart';

Future<List<ActivityLogModel>> getCachedActivityLogsOp(
  LocalDatabase localDatabase,
  EncryptionService enc,
  String userId,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.activityLogs,
      where: '${ActivityLogsCols.userId} = ?',
      whereArgs: [userId],
      orderBy: '${CommonCols.createdAt} DESC',
    );
    if (results.isEmpty) throw CacheException('No cached activity logs found for user: $userId');
    return results.map((row) {
      final decryptedRow = Map<String, dynamic>.from(row);
      decryptedRow['details'] = enc.decryptField(row['details'] as String?);
      return ActivityLogModel.fromMap(decryptedRow);
    }).toList();
  } catch (e) {
    if (e is CacheException) rethrow;
    throw CacheException(e.toString());
  }
}
