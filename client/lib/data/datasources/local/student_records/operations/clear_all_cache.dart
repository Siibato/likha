import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';

Future<void> clearAllStudentRecordsCache(
  LocalDatabase localDatabase,
) async {
  try {
    final db = await localDatabase.database;
    await db.delete(DbTables.learnerDetails);
    await db.delete(DbTables.attendanceRecords);
    await db.delete(DbTables.coreValuesRecords);
    await db.delete(DbTables.studentSchoolHistory);
    await db.delete(DbTables.previousSchoolSubjects);
    await db.delete(DbTables.previousSchoolAttendance);
  } catch (e) {
    throw CacheException('Failed to clear student records cache: $e');
  }
}
