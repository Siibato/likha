import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/student_records/previous_attendance_model.dart';

Future<List<PreviousAttendanceModel>> getCachedPreviousAttendance(
  LocalDatabase localDatabase,
  String studentId, {
  String? schoolHistoryId,
}) async {
  try {
    final db = await localDatabase.database;
    final where = StringBuffer('${PreviousSchoolAttendanceCols.studentId} = ?');
    final args = <dynamic>[studentId];
    if (schoolHistoryId != null) {
      where.write(' AND ${PreviousSchoolAttendanceCols.schoolHistoryId} = ?');
      args.add(schoolHistoryId);
    }
    final results = await db.query(
      DbTables.previousSchoolAttendance,
      where: where.toString(),
      whereArgs: args,
      orderBy: '${PreviousSchoolAttendanceCols.month} ASC',
    );
    return results.map(PreviousAttendanceModel.fromJson).toList();
  } catch (e) {
    throw CacheException('Failed to get cached previous attendance: $e');
  }
}
