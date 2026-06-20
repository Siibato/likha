import 'dart:convert';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/assessments/submission_model.dart';

Future<StudentResultModel?> getCachedStudentResults(
  LocalDatabase localDatabase,
  String submissionId,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.studentResultsCache,
      where: '${StudentResultsCacheCols.submissionId} = ?',
      whereArgs: [submissionId],
    );
    if (results.isEmpty) return null;
    final json = jsonDecode(results.first['results_json'] as String) as Map<String, dynamic>;
    return StudentResultModel.fromJson(json);
  } catch (e) {
    return null;
  }
}
