import 'dart:convert';

import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/logging/sf9_logger.dart';

Future<void> cacheSf9(
  LocalDatabase localDatabase,
  String classId,
  String studentId,
  Map<String, dynamic> data,
) async {
  final log = Sf9Logger.instance;
  try {
    final db = await localDatabase.database;
    final encoded = jsonEncode(data);
    log.log('cacheSf9: writing key sf9:$classId:$studentId, JSON length=${encoded.length}');
    log.log('cacheSf9: data keys = ${data.keys.toList()}');

    final missingFields = <String>[];
    void checkField(String key, {bool isRequired = false}) {
      if (!data.containsKey(key)) {
        missingFields.add('$key${isRequired ? ' (required)' : ''}');
      } else if (data[key] == null) {
        missingFields.add('$key (null)');
      }
    }

    checkField('student_id', isRequired: true);
    checkField('student_name', isRequired: true);
    checkField('grade_level');
    checkField('school_year');
    checkField('section');
    checkField('lrn');
    checkField('sex');
    checkField('track_strand');
    checkField('curriculum');
    checkField('teacher_name');
    checkField('term_type');
    checkField('subjects');
    checkField('general_average');

    if (missingFields.isNotEmpty) {
      log.warn('cacheSf9: missing/null fields being written => $missingFields');
    }

    await db.insert(
      DbTables.syncMetadata,
      {
        SyncMetadataCols.key: 'sf9:$classId:$studentId',
        SyncMetadataCols.value: encoded,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    log.log('cacheSf9: write succeeded for sf9:$classId:$studentId');
  } catch (e) {
    log.error('cacheSf9: write failed', e);
    throw CacheException('Failed to cache SF9: $e');
  }
}
