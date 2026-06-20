import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/student_records/previous_subject_model.dart';

Future<List<PreviousSubjectModel>> getCachedPreviousSubjects(
  LocalDatabase localDatabase,
  String studentId, {
  String? schoolHistoryId,
}) async {
  try {
    final db = await localDatabase.database;
    final where = StringBuffer('${PreviousSchoolSubjectsCols.studentId} = ?');
    final args = <dynamic>[studentId];
    if (schoolHistoryId != null) {
      where.write(' AND ${PreviousSchoolSubjectsCols.schoolHistoryId} = ?');
      args.add(schoolHistoryId);
    }
    final results = await db.query(
      DbTables.previousSchoolSubjects,
      where: where.toString(),
      whereArgs: args,
    );
    return results.map(PreviousSubjectModel.fromJson).toList();
  } catch (e) {
    throw CacheException('Failed to get cached previous subjects: $e');
  }
}
