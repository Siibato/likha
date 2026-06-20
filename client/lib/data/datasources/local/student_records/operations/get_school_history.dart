import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/student_records/school_history_model.dart';

Future<List<SchoolHistoryModel>> getCachedSchoolHistory(
  LocalDatabase localDatabase,
  String studentId,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.studentSchoolHistory,
      where: '${StudentSchoolHistoryCols.studentId} = ? AND ${CommonCols.deletedAt} IS NULL',
      whereArgs: [studentId],
      orderBy: '${StudentSchoolHistoryCols.schoolYear} ASC',
    );
    return results.map(SchoolHistoryModel.fromJson).toList();
  } catch (e) {
    throw CacheException('Failed to get cached school history: $e');
  }
}
