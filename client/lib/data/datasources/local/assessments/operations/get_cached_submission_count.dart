import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';

Future<int> getCachedSubmissionCount(
  LocalDatabase localDatabase,
  String assessmentId,
) async {
  try {
    final db = await localDatabase.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM assessment_submissions WHERE assessment_id = ? AND deleted_at IS NULL',
      [assessmentId],
    );
    final count = (result.first['count'] as int?) ?? 0;
    return count;
  } catch (e) {
    throw CacheException('Failed to get submission count: $e');
  }
}
