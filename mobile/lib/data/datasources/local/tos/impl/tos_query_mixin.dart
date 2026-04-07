import 'package:likha/core/database/db_schema.dart';
import 'package:likha/data/models/tos/tos_model.dart';
import 'package:likha/data/models/tos/melcs_model.dart';
import '../tos_local_datasource_base.dart';

mixin TosQueryMixin on TosLocalDataSourceBase {
  @override
  Future<List<TosModel>> getTosByClass(String classId) async {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.tableOfSpecifications,
      where: '${TosCols.classId} = ? AND ${CommonCols.deletedAt} IS NULL',
      whereArgs: [classId],
      orderBy: '${TosCols.quarter} ASC',
    );
    return results.map((row) => TosModel.fromMap(row)).toList();
  }

  @override
  Future<TosModel?> getTosById(String tosId) async {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.tableOfSpecifications,
      where: '${CommonCols.id} = ? AND ${CommonCols.deletedAt} IS NULL',
      whereArgs: [tosId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return TosModel.fromMap(results.first);
  }

  @override
  Future<List<CompetencyModel>> getCompetenciesByTos(String tosId) async {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.tosCompetencies,
      where:
          '${TosCompetenciesCols.tosId} = ? AND ${CommonCols.deletedAt} IS NULL',
      whereArgs: [tosId],
      orderBy: '${TosCompetenciesCols.orderIndex} ASC',
    );
    return results.map((row) => CompetencyModel.fromMap(row)).toList();
  }

  @override
  Future<List<MelcEntryModel>> searchMelcs({
    String? subject,
    String? gradeLevel,
    int? quarter,
    String? query,
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
    if (quarter != null) {
      conditions.add('(${MelcsCols.quarter} = ? OR ${MelcsCols.quarter} IS NULL)');
      args.add(quarter);
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
      limit: 50,
    );

    // MelcEntryModel.fromJson uses the same snake_case keys as SQLite columns
    return results.map((row) => MelcEntryModel.fromJson(row)).toList();
  }
}
