import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:sqflite/sqflite.dart';
import 'package:likha/core/database/local_database.dart';

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
  activityLog('activityLog');

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
  upload('upload'),
  saveAnswers('save_answers'),
  releaseResults('release_results'),
  overrideAnswer('override_answer'),
  addEnrollment('add_enrollment'),
  removeEnrollment('remove_enrollment');

  const SyncOperation(this.serverValue);
  final String serverValue;

  /// DB-stored value — matches Dart .name (camelCase). Stable: existing SQLite rows use this format.
  String get dbValue => name;
}

enum SyncStatus {
  pending,
  failed;

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
    return SyncQueueEntry(
      id: map['id'] as String,
      entityType: SyncEntityType.values.firstWhere(
        (e) => e.dbValue == map['entity_type'],
      ),
      operation: SyncOperation.values.firstWhere(
        (e) => e.dbValue == map['operation'],
      ),
      payload: _parseJsonString(map['payload'] as String),
      status: SyncStatus.values.firstWhere(
        (e) => e.dbValue == map['status'],
      ),
      retryCount: map['retry_count'] as int,
      maxRetries: map['max_retries'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastAttemptedAt: map['last_attempted_at'] != null
          ? DateTime.parse(map['last_attempted_at'] as String)
          : null,
      errorMessage: map['error_message'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType.dbValue,
      'operation': operation.dbValue,
      'payload': _stringifyJson(payload),
      'status': status.dbValue,
      'retry_count': retryCount,
      'max_retries': maxRetries,
      'created_at': createdAt.toIso8601String(),
      'last_attempted_at': lastAttemptedAt?.toIso8601String(),
      'error_message': errorMessage,
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
}

class SyncQueueImpl implements SyncQueue {
  final LocalDatabase _localDatabase;

  SyncQueueImpl(this._localDatabase);

  @override
  Future<void> enqueue(SyncQueueEntry entry, {Transaction? txn}) async {
    debugPrint('[SyncQueue] enqueue: Adding ${entry.entityType.dbValue} ${entry.operation.dbValue} to queue, ID=${entry.id}');

    if (txn != null) {
      debugPrint('[SyncQueue] enqueue: Using provided transaction object');
      await txn.insert(
        'sync_queue',
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      debugPrint('[SyncQueue] enqueue: Getting database connection');
      final db = await _localDatabase.database;
      await db.insert(
        'sync_queue',
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    debugPrint('[SyncQueue] enqueue: Entry added to queue successfully');
  }

  @override
  Future<List<SyncQueueEntry>> getAllRetriable() async {
    final db = await _localDatabase.database;
    final results = await db.query(
      'sync_queue',
      where: 'status = ? AND retry_count < max_retries',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
    return results.map(SyncQueueEntry.fromMap).toList();
  }

  @override
  Future<void> markSucceeded(String id) async {
    final db = await _localDatabase.database;
    await db.update(
      'sync_queue',
      {'status': 'succeeded'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> markFailed(String id, String errorMessage) async {
    final db = await _localDatabase.database;
    await db.update(
      'sync_queue',
      {
        'status': 'failed',
        'error_message': errorMessage,
        'last_attempted_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> incrementRetry(String id) async {
    final db = await _localDatabase.database;
    await db.rawUpdate(
      'UPDATE sync_queue SET retry_count = retry_count + 1, last_attempted_at = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), id],
    );
  }

  @override
  Future<void> clear() async {
    final db = await _localDatabase.database;
    await db.delete('sync_queue');
  }

  @override
  Future<SyncQueueEntry?> getById(String id) async {
    final db = await _localDatabase.database;
    final results = await db.query(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return SyncQueueEntry.fromMap(results.first);
  }

  @override
  Future<int> getPendingCount() async {
    final db = await _localDatabase.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM sync_queue WHERE status = 'pending'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<List<SyncQueueEntry>> getByEntityAndOperation(SyncEntityType entityType, SyncOperation operation) async {
    final db = await _localDatabase.database;
    final results = await db.query(
      'sync_queue',
      where: 'entity_type = ? AND operation = ?',
      whereArgs: [
        entityType.dbValue,
        operation.dbValue,
      ],
      orderBy: 'created_at ASC',
    );
    return results.map(SyncQueueEntry.fromMap).toList();
  }

  Future<void> deleteEntry(String id) async {
    final db = await _localDatabase.database;
    await db.delete(
      'sync_queue',
      where: 'id = ?',
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
