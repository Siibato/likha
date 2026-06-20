import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/student_records/learner_details_model.dart';

Future<LearnerDetailsModel?> getCachedLearnerDetails(
  LocalDatabase localDatabase,
  String userId,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.learnerDetails,
      where: '${LearnerDetailsCols.userId} = ? AND ${CommonCols.deletedAt} IS NULL',
      whereArgs: [userId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return LearnerDetailsModel.fromJson(results.first);
  } catch (e) {
    throw CacheException('Failed to get cached learner details: $e');
  }
}
