import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/student_records/core_values_record_model.dart';

Future<List<CoreValuesRecordModel>> getCachedCoreValues(
  LocalDatabase localDatabase,
  String studentId, {
  String? classId,
  String? schoolYear,
}) async {
  try {
    final db = await localDatabase.database;
    final where = StringBuffer('${CoreValuesRecordsCols.studentId} = ?');
    final args = <dynamic>[studentId];
    if (classId != null) {
      where.write(' AND ${CoreValuesRecordsCols.classId} = ?');
      args.add(classId);
    }
    if (schoolYear != null) {
      where.write(' AND ${CoreValuesRecordsCols.schoolYear} = ?');
      args.add(schoolYear);
    }
    final results = await db.query(
      DbTables.coreValuesRecords,
      where: where.toString(),
      whereArgs: args,
    );
    return results.map(CoreValuesRecordModel.fromJson).toList();
  } catch (e) {
    throw CacheException('Failed to get cached core values: $e');
  }
}
