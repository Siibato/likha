import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/student_records/attendance_record_model.dart';

Future<List<AttendanceRecordModel>> getCachedAttendance(
  LocalDatabase localDatabase,
  String studentId, {
  String? classId,
  String? schoolYear,
}) async {
  try {
    final db = await localDatabase.database;
    final where = StringBuffer('${AttendanceRecordsCols.studentId} = ?');
    final args = <dynamic>[studentId];
    if (classId != null) {
      where.write(' AND ${AttendanceRecordsCols.classId} = ?');
      args.add(classId);
    }
    if (schoolYear != null) {
      where.write(' AND ${AttendanceRecordsCols.schoolYear} = ?');
      args.add(schoolYear);
    }
    final results = await db.query(
      DbTables.attendanceRecords,
      where: where.toString(),
      whereArgs: args,
      orderBy: '${AttendanceRecordsCols.month} ASC',
    );
    return results.map(AttendanceRecordModel.fromJson).toList();
  } catch (e) {
    throw CacheException('Failed to get cached attendance: $e');
  }
}
