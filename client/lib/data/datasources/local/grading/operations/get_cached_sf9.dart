import 'dart:convert';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/logging/sf9_logger.dart';

Future<Map<String, dynamic>> getCachedSf9(
  LocalDatabase localDatabase,
  String classId,
  String studentId,
) async {
  final log = Sf9Logger.instance;
  try {
    final db = await localDatabase.database;
    final result = await db.query(
      DbTables.syncMetadata,
      columns: [SyncMetadataCols.value],
      where: '${SyncMetadataCols.key} = ?',
      whereArgs: ['sf9:$classId:$studentId'],
    );
    if (result.isEmpty) {
      log.log('getCachedSf9: no row found for key sf9:$classId:$studentId');
      throw CacheException('SF9 not found in cache');
    }
    final value = result.first[SyncMetadataCols.value] as String;
    final decoded = jsonDecode(value) as Map<String, dynamic>;

    log.log('getCachedSf9: raw JSON for sf9:$classId:$studentId => $value');

    final keys = decoded.keys.toList();
    log.log('getCachedSf9: decoded keys = $keys');

    final missingFields = <String>[];
    void checkField(String key, {bool isRequired = false}) {
      if (!decoded.containsKey(key)) {
        missingFields.add('$key${isRequired ? ' (required)' : ''}');
      } else if (decoded[key] == null) {
        missingFields.add('$key (null)');
      }
    }

    checkField('student_id', isRequired: true);
    checkField('student_name', isRequired: true);
    checkField('grade_level');
    checkField('school_year');
    checkField('section');
    checkField('lrn');
    checkField('age');
    checkField('sex');
    checkField('track_strand');
    checkField('curriculum');
    checkField('teacher_name');
    checkField('term_type');
    checkField('subjects');
    checkField('general_average');

    if (missingFields.isNotEmpty) {
      log.warn('getCachedSf9: missing/null fields => $missingFields');
    } else {
      log.log('getCachedSf9: all expected fields present');
    }

    if (decoded['student_name'] == 'Unknown Student') {
      log.warn('getCachedSf9: student_name is "Unknown Student" — will be treated as cache miss');
    }

    final subjects = decoded['subjects'];
    if (subjects == null) {
      log.warn('getCachedSf9: subjects is null');
    } else if (subjects is List && subjects.isEmpty) {
      log.warn('getCachedSf9: subjects list is empty');
    } else if (subjects is List) {
      log.log('getCachedSf9: subjects count = ${subjects.length}');
      for (var i = 0; i < subjects.length; i++) {
        final s = subjects[i] as Map;
        log.log('getCachedSf9: subject[$i] => ${jsonEncode(s)}');
      }
    }

    final ga = decoded['general_average'];
    if (ga != null) {
      log.log('getCachedSf9: general_average => ${jsonEncode(ga)}');
    }

    return decoded;
  } on CacheException {
    rethrow;
  } catch (e) {
    log.error('getCachedSf9: unexpected error', e);
    throw CacheException('Failed to read cached SF9: $e');
  }
}
