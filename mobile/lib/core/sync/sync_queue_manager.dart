import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:likha/core/database/local_database.dart';

class SyncQueueEntry {
  final String id;
  final String entityType;
  final String operation;
  final Map<String, dynamic> payload;
  final String status; // pending, succeeded, failed
  final int retryCount;
  final int maxRetries;
  final DateTime createdAt;
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
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'operation': operation,
      'payload': payload,
      'status': status,
      'retry_count': retryCount,
      'max_retries': maxRetries,
      'created_at': createdAt.toIso8601String(),
      'error_message': errorMessage,
    };
  }

  factory SyncQueueEntry.fromMap(Map<String, dynamic> map) {
    return SyncQueueEntry(
      id: map['id'] as String,
      entityType: map['entity_type'] as String,
      operation: map['operation'] as String,
      payload: map['payload'] as Map<String, dynamic>,
      status: map['status'] as String,
      retryCount: map['retry_count'] as int? ?? 0,
      maxRetries: map['max_retries'] as int? ?? 5,
      createdAt: DateTime.parse(map['created_at'] as String),
      errorMessage: map['error_message'] as String?,
    );
  }
}

class SyncQueueManager {
  final LocalDatabase _localDatabase;

  SyncQueueManager(this._localDatabase);

  /// Enqueue an offline mutation
  Future<void> enqueue({
    required String entityType,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final db = await _localDatabase.database;
    final entry = SyncQueueEntry(
      id: const Uuid().v4(),
      entityType: entityType,
      operation: operation,
      payload: payload,
      status: 'pending',
      retryCount: 0,
      maxRetries: 5,
      createdAt: DateTime.now(),
    );

    await db.insert(
      'sync_queue',
      {
        'id': entry.id,
        'entity_type': entry.entityType,
        'operation': entry.operation,
        'payload': entry.payload,
        'status': entry.status,
        'retry_count': entry.retryCount,
        'max_retries': entry.maxRetries,
        'created_at': entry.createdAt.toIso8601String(),
        'error_message': null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all pending operations
  Future<List<SyncQueueEntry>> getPendingOperations() async {
    final db = await _localDatabase.database;
    final rows = await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );

    return rows.map((row) {
      return SyncQueueEntry(
        id: row['id'] as String,
        entityType: row['entity_type'] as String,
        operation: row['operation'] as String,
        payload: row['payload'] as Map<String, dynamic>,
        status: row['status'] as String,
        retryCount: row['retry_count'] as int? ?? 0,
        maxRetries: row['max_retries'] as int? ?? 5,
        createdAt: DateTime.parse(row['created_at'] as String),
        errorMessage: row['error_message'] as String?,
      );
    }).toList();
  }

  /// Mark operation as succeeded and remove from queue
  Future<void> markSucceeded(String entryId) async {
    final db = await _localDatabase.database;
    await db.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  /// Mark operation as failed (increment retry or remove if max reached)
  Future<void> markFailed(String entryId, String error) async {
    final db = await _localDatabase.database;

    final rows = await db.query(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [entryId],
    );

    if (rows.isEmpty) return;

    final retryCount = (rows[0]['retry_count'] as int?) ?? 0;
    final maxRetries = (rows[0]['max_retries'] as int?) ?? 5;

    if (retryCount >= maxRetries) {
      // Give up after max retries
      await db.delete('sync_queue', where: 'id = ?', whereArgs: [entryId]);
    } else {
      // Keep in queue for retry
      await db.update(
        'sync_queue',
        {
          'status': 'pending',
          'retry_count': retryCount + 1,
          'error_message': error,
        },
        where: 'id = ?',
        whereArgs: [entryId],
      );
    }
  }

  /// Check if there are pending operations
  Future<bool> hasPendingOperations() async {
    final db = await _localDatabase.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM sync_queue WHERE status = ?',
        ['pending'],
      ),
    );
    return count != null && count > 0;
  }
}
