import 'package:sqflite/sqflite.dart';
import 'package:likha/core/database/local_database.dart';

class ChangeLogRepository {
  final LocalDatabase _localDatabase;

  static const String _lastSyncedSequenceKey = 'last_synced_sequence';

  ChangeLogRepository(this._localDatabase);

  /// Get the last synced sequence number from local storage
  /// Defaults to 0 if not set
  Future<int> getLastSyncedSequence() async {
    try {
      final db = await _localDatabase.database;
      final result = await db.query(
        'sync_metadata',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [_lastSyncedSequenceKey],
      );

      if (result.isEmpty) {
        return 0;
      }

      final value = result.first['value'] as String?;
      return int.tryParse(value ?? '0') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Save the last synced sequence number to local storage
  Future<void> saveLastSyncedSequence(int sequence) async {
    try {
      final db = await _localDatabase.database;
      await db.insert(
        'sync_metadata',
        {
          'key': _lastSyncedSequenceKey,
          'value': sequence.toString(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      // Error saving - continue
    }
  }

  /// Clear all sync metadata
  Future<void> clearSyncMetadata() async {
    try {
      final db = await _localDatabase.database;
      await db.delete('sync_metadata');
    } catch (e) {
      // Error clearing - continue
    }
  }
}
