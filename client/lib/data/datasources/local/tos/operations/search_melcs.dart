import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/tos/melcs_model.dart';

Future<List<MelcEntryModel>> searchMelcs(
  LocalDatabase localDatabase, {
  String? subject,
  String? gradeLevel,
  int? termNumber,
  String? query,
  int limit = 30,
  int offset = 0,
}) async {
  final db = await localDatabase.database;

  final conditions = <String>[];
  final args = <dynamic>[];

  if (subject != null) {
    conditions.add('${MelcsCols.subject} = ?');
    args.add(subject);
  }
  if (gradeLevel != null) {
    conditions.add('${MelcsCols.gradeLevel} = ?');
    args.add(gradeLevel);
  }
  if (termNumber != null) {
    conditions.add('(quarter = ? OR quarter IS NULL)');
    args.add(termNumber);
  }
  if (query != null && query.isNotEmpty) {
    conditions.add(
      '(${MelcsCols.competencyCode} LIKE ? OR ${MelcsCols.competencyText} LIKE ?)',
    );
    args.add('%$query%');
    args.add('%$query%');
  }

  final where = conditions.isEmpty ? null : conditions.join(' AND ');

  final results = await db.query(
    DbTables.melcs,
    where: where,
    whereArgs: args.isEmpty ? null : args,
    orderBy: '${MelcsCols.competencyCode} ASC',
    limit: limit,
    offset: offset,
  );

  // MelcEntryModel.fromJson uses the same snake_case keys as SQLite columns
  return results.map((row) => MelcEntryModel.fromJson(row)).toList();
}
