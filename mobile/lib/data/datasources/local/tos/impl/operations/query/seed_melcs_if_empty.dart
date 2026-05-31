import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/datasources/local/tos/melcs_seed.dart';

Future<void> seedMelcsIfEmptyOp(LocalDatabase localDatabase) async {
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
