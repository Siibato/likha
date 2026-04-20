import 'package:likha/core/database/db_schema.dart';
import 'package:likha/data/datasources/local/tos/melcs_seed.dart';
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
      orderBy: '${TosCols.gradingPeriodNumber} ASC',
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
  Future<CompetencyModel?> getCompetencyById(String competencyId) async {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.tosCompetencies,
      where: '${CommonCols.id} = ? AND ${CommonCols.deletedAt} IS NULL',
      whereArgs: [competencyId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return CompetencyModel.fromMap(results.first);
  }

  @override
  Future<List<MelcEntryModel>> searchMelcs({
    String? subject,
    String? gradeLevel,
    int? gradingPeriodNumber,
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
    if (gradingPeriodNumber != null) {
      conditions.add('(quarter = ? OR quarter IS NULL)');
      args.add(gradingPeriodNumber);
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

  @override
  Future<void> seedMelcsIfEmpty() async {
    final db = await localDatabase.database;
    final countResult = await db.rawQuery('SELECT COUNT(*) as c FROM ${DbTables.melcs}');
    final count = (countResult.first['c'] as int?) ?? 0;
    if (count > 0) return;

    final batch = db.batch();
    for (final row in kMelcsSeedData) {
      batch.insert(DbTables.melcs, {
        MelcsCols.subject: row['subject'],
        MelcsCols.gradeLevel: row['grade_level'],
        'quarter': row['quarter'],
        MelcsCols.competencyCode: row['competency_code'],
        MelcsCols.competencyText: row['competency_text'],
        MelcsCols.domain: row['domain'],
      });
    }
    await batch.commit(noResult: true);
  }
}
