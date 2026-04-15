import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/logging/core_logger.dart';

// Re-export Transaction type from sqflite for convenience
export 'package:sqflite/sqflite.dart' show Transaction;

enum SyncEntityType {
  user('user'),
  classEntity('class'),
  assessment('assessment'),
  question('question'),
  assessmentSubmission('assessment_submission'),
  assignment('assignment'),
  assignmentSubmission('assignment_submission'),
  submissionFile('submission_file'),
  learningMaterial('learning_material'),
  materialFile('material_file'),
  adminUser('admin_user'),
  activityLog('activityLog'),
  gradeConfig('grade_config'),
  gradeItem('grade_item'),
  gradeScore('grade_score'),
  tableOfSpecifications('table_of_specifications'),
  tosCompetency('tos_competency');

  const SyncEntityType(this.serverValue);
  final String serverValue;

  /// DB-stored value — matches Dart .name (camelCase). Stable: existing SQLite rows use this format.
  String get dbValue => name;
}

enum SyncOperation {
  create('create'),
  update('update'),
  delete('delete'),
  submit('submit'),
  grade('grade'),
  publish('publish'),
  unpublish('unpublish'),
  upload('upload'),
  saveAnswers('save_answers'),
  releaseResults('release_results'),
  overrideAnswer('override_answer'),
  addEnrollment('add_enrollment'),
  removeEnrollment('remove_enrollment'),
  saveScores('save_scores'),
  setOverride('set_override'),
  clearOverride('clear_override'),
  setup('setup');

  const SyncOperation(this.serverValue);
  final String serverValue;

  /// DB-stored value — matches Dart .name (camelCase). Stable: existing SQLite rows use this format.
  String get dbValue => name;
}

enum SyncStatus {
  pending,
  failed,
  succeeded;

  /// DB-stored value — matches Dart .name.
  String get dbValue => name;
}

class SyncQueueEntry {
  final String id;
  final SyncEntityType entityType;
  final SyncOperation operation;
  final Map<String, dynamic> payload;
  final SyncStatus status;
  final int retryCount;
  final int maxRetries;
  final DateTime createdAt;
  final DateTime? lastAttemptedAt;
  final String? errorMessage;

  SyncQueueEntry({
    required this.id,
    required this.entityType,
    required this.operation,
    required this.payload,
    required this.status,
    required this.retryCount,
    required this.maxRetries,
    required this.createdAt,
    this.lastAttemptedAt,
    this.errorMessage,
  });

  factory SyncQueueEntry.fromMap(Map<String, dynamic> map) {
    final entityTypeValue = map[SyncQueueCols.entityType] as String?;
    final operationValue = map[SyncQueueCols.operation] as String?;
    final statusValue = map[SyncQueueCols.status] as String?;

    CoreLogger.instance.log('fromMap: entityType=$entityTypeValue, operation=$operationValue, status=$statusValue');

    final entityType = SyncEntityType.values.firstWhere(
      (e) => e.dbValue == entityTypeValue,
      orElse: () {
        CoreLogger.instance.error('fromMap: Unknown entityType "$entityTypeValue", defaulting to user');
        return SyncEntityType.user;
      },
    );

    final operation = SyncOperation.values.firstWhere(
      (e) => e.dbValue == operationValue,
      orElse: () {
        CoreLogger.instance.error('fromMap: Unknown operation "$operationValue", defaulting to create');
        return SyncOperation.create;
      },
    );

    final status = SyncStatus.values.firstWhere(
      (e) => e.dbValue == statusValue,
      orElse: () {
        CoreLogger.instance.error('fromMap: Unknown status "$statusValue", defaulting to pending');
        return SyncStatus.pending;
      },
    );

    return SyncQueueEntry(
      id: map[CommonCols.id] as String,
      entityType: entityType,
      operation: operation,
      payload: _parseJsonString(map[SyncQueueCols.payload] as String),
      status: status,
      retryCount: map[SyncQueueCols.retryCount] as int,
      maxRetries: map[SyncQueueCols.maxRetries] as int,
      createdAt: DateTime.parse(map[CommonCols.createdAt] as String),
      lastAttemptedAt: map[SyncQueueCols.lastAttemptedAt] != null
          ? DateTime.parse(map[SyncQueueCols.lastAttemptedAt] as String)
          : null,
      errorMessage: map[SyncQueueCols.errorMessage] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      CommonCols.id: id,
      SyncQueueCols.entityType: entityType.dbValue,
      SyncQueueCols.operation: operation.dbValue,
      SyncQueueCols.payload: _stringifyJson(payload),
      SyncQueueCols.status: status.dbValue,
      SyncQueueCols.retryCount: retryCount,
      SyncQueueCols.maxRetries: maxRetries,
      CommonCols.createdAt: createdAt.toIso8601String(),
      SyncQueueCols.lastAttemptedAt: lastAttemptedAt?.toIso8601String(),
      SyncQueueCols.errorMessage: errorMessage,
    };
  }
}

abstract class SyncQueue {
  Future<void> enqueue(SyncQueueEntry entry, {Transaction? txn});
  Future<List<SyncQueueEntry>> getAllRetriable();
  Future<List<SyncQueueEntry>> getByEntityAndOperation(SyncEntityType entityType, SyncOperation operation);
  Future<void> markSucceeded(String id);
  Future<void> markFailed(String id, String errorMessage);
  Future<void> incrementRetry(String id);
  Future<void> clear();
  Future<SyncQueueEntry?> getById(String id);
  Future<int> getPendingCount();
  Future<void> updatePendingSubmissionIds(String oldId, String newId);
}

class SyncQueueImpl implements SyncQueue {
  final LocalDatabase _localDatabase;

  SyncQueueImpl(this._localDatabase);

  @override
  Future<void> enqueue(SyncQueueEntry entry, {Transaction? txn}) async {
    CoreLogger.instance.log('enqueue: Adding ${entry.entityType.dbValue} ${entry.operation.dbValue} to queue, ID=${entry.id}');

    if (txn != null) {
      CoreLogger.instance.log('enqueue: Using provided transaction object');
      await txn.insert(
        DbTables.syncQueue,
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      CoreLogger.instance.log('enqueue: Getting database connection');
      final db = await _localDatabase.database;
      await db.insert(
        DbTables.syncQueue,
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    CoreLogger.instance.log('enqueue: Entry added to queue successfully');
  }

  @override
  Future<List<SyncQueueEntry>> getAllRetriable() async {
    final db = await _localDatabase.database;
    final results = await db.query(
      DbTables.syncQueue,
      where: '${SyncQueueCols.status} = ? AND ${SyncQueueCols.retryCount} < ${SyncQueueCols.maxRetries}',
      whereArgs: [SyncStatus.pending.dbValue],
      orderBy: '${CommonCols.createdAt} ASC',
    );
    return results.map(SyncQueueEntry.fromMap).toList();
  }

  @override
  Future<void> markSucceeded(String id) async {
    final db = await _localDatabase.database;
    await db.update(
      DbTables.syncQueue,
      {SyncQueueCols.status: 'succeeded'},
      where: '${CommonCols.id} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> markFailed(String id, String errorMessage) async {
    final db = await _localDatabase.database;
    await db.update(
      DbTables.syncQueue,
      {
        SyncQueueCols.status: SyncStatus.failed.dbValue,
        SyncQueueCols.errorMessage: errorMessage,
        SyncQueueCols.lastAttemptedAt: DateTime.now().toIso8601String(),
      },
      where: '${CommonCols.id} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> incrementRetry(String id) async {
    final db = await _localDatabase.database;
    await db.rawUpdate(
      'UPDATE ${DbTables.syncQueue} SET ${SyncQueueCols.retryCount} = ${SyncQueueCols.retryCount} + 1, ${SyncQueueCols.lastAttemptedAt} = ? WHERE ${CommonCols.id} = ?',
      [DateTime.now().toIso8601String(), id],
    );
  }

  @override
  Future<void> clear() async {
    final db = await _localDatabase.database;
    await db.delete(DbTables.syncQueue);
  }

  @override
  Future<SyncQueueEntry?> getById(String id) async {
    final db = await _localDatabase.database;
    final results = await db.query(
      DbTables.syncQueue,
      where: '${CommonCols.id} = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return SyncQueueEntry.fromMap(results.first);
  }

  @override
  Future<int> getPendingCount() async {
    final db = await _localDatabase.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM ${DbTables.syncQueue} WHERE ${SyncQueueCols.status} = '${SyncStatus.pending.dbValue}'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<List<SyncQueueEntry>> getByEntityAndOperation(SyncEntityType entityType, SyncOperation operation) async {
    CoreLogger.instance.log('getByEntityAndOperation: entityType=${entityType.dbValue}, operation=${operation.dbValue}');
    final db = await _localDatabase.database;
    final results = await db.query(
      DbTables.syncQueue,
      where: '${SyncQueueCols.entityType} = ? AND ${SyncQueueCols.operation} = ?',
      whereArgs: [
        entityType.dbValue,
        operation.dbValue,
      ],
      orderBy: '${CommonCols.createdAt} ASC',
    );
    CoreLogger.instance.log('getByEntityAndOperation: Found ${results.length} entries');
    return results.map(SyncQueueEntry.fromMap).toList();
  }

  @override
  Future<void> updatePendingSubmissionIds(String oldId, String newId) async {
    final db = await _localDatabase.database;
    await db.rawUpdate(
      '''UPDATE ${DbTables.syncQueue}
         SET ${SyncQueueCols.payload} = json_replace(${SyncQueueCols.payload}, '\$.submission_id', ?)
         WHERE ${SyncQueueCols.status} = '${SyncStatus.pending.dbValue}'
           AND json_extract(${SyncQueueCols.payload}, '\$.submission_id') = ?''',
      [newId, oldId],
    );
  }

  Future<void> deleteEntry(String id) async {
    final db = await _localDatabase.database;
    await db.delete(
      DbTables.syncQueue,
      where: '${CommonCols.id} = ?',
      whereArgs: [id],
    );
  }
}

String _stringifyJson(Map<String, dynamic> json) {
  return jsonEncode(json);
}

Map<String, dynamic> _parseJsonString(String jsonStr) {
  try {
    final decoded = jsonDecode(jsonStr);
    return decoded is Map<String, dynamic> ? decoded : {};
  } catch (_) {
    return {};
  }
}
