import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/tos/melcs_model.dart';

Future<void> cacheMelcs(
  LocalDatabase localDatabase,
  List<MelcEntryModel> melcs,
) async {
  final db = await localDatabase.database;
  final batch = db.batch();

  for (final melc in melcs) {
    batch.insert(
      DbTables.melcs,
      {
        'id': melc.id,
        MelcsCols.subject: melc.subject,
        MelcsCols.gradeLevel: melc.gradeLevel,
        'quarter': melc.termNumber,
        MelcsCols.competencyCode: melc.competencyCode,
        MelcsCols.competencyText: melc.competencyText,
        MelcsCols.domain: melc.domain,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  await batch.commit(noResult: true);
}
