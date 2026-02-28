import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:likha/core/database/local_database.dart';

enum SyncEntityType {
  user,
  classEntity,
  assessment,
  question,
  assessmentSubmission,
  assignment,
  assignmentSubmission,
  submissionFile,
  learningMaterial,
  materialFile,
  adminUser,
  activityLog
}

enum SyncOperation { create, update, delete, submit, grade, publish, upload, saveAnswers, releaseResults, overrideAnswer, addEnrollment, removeEnrollment }

enum SyncStatus { pending, failed }

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
        (e) => e.toString().split('.').last == map['entity_type'],
      ),
      operation: SyncOperation.values.firstWhere(
        (e) => e.toString().split('.').last == map['operation'],
      ),
      payload: _parseJsonString(map['payload'] as String),
      status: SyncStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
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
      'entity_type': entityType.toString().split('.').last,
      'operation': operation.toString().split('.').last,
      'payload': _stringifyJson(payload),
      'status': status.toString().split('.').last,
      'retry_count': retryCount,
      'max_retries': maxRetries,
      'created_at': createdAt.toIso8601String(),
      'last_attempted_at': lastAttemptedAt?.toIso8601String(),
      'error_message': errorMessage,
    };
  }
}

abstract class SyncQueue {
  Future<void> enqueue(SyncQueueEntry entry);
  Future<List<SyncQueueEntry>> getAllRetriable();
  Future<void> markSucceeded(String id);
  Future<void> markFailed(String id, String errorMessage);
  Future<void> incrementRetry(String id);
  Future<void> clear();
  Future<SyncQueueEntry?> getById(String id);
}

class SyncQueueImpl implements SyncQueue {
  final LocalDatabase _localDatabase;

  SyncQueueImpl(this._localDatabase);

  @override
  Future<void> enqueue(SyncQueueEntry entry) async {
    final db = await _localDatabase.database;
    await db.insert(
      'sync_queue',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
    await db.delete(
      'sync_queue',
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
