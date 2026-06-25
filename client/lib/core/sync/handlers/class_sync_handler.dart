import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/logging/sync_logger.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/sync/sync_result.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/classes/class_remote_datasource.dart';
import 'package:likha/data/models/classes/class_model.dart';

/// Sync handler for all [SyncEntityType.classEntity] operations.
///
/// Invoked by the outbound sync engine for each pending class queue entry.
/// Calls the corresponding [ClassRemoteDataSource] method and reconciles
/// the server response into the local DB.
class ClassSyncHandler {
  final ClassRemoteDataSource _remote;
  final ClassLocalDataSource _local;
  final LocalDatabase _localDatabase;
  final SyncLogger _log;

  ClassSyncHandler(
    this._remote,
    this._local,
    this._localDatabase,
    this._log,
  );

  Future<SyncResult> handle(SyncQueueEntry entry) async {
    try {
      switch (entry.entityType) {
        case SyncEntityType.classEntity:
          return await _handleClass(entry);
        default:
          return SyncResult.permanentFailure(
            'Unsupported class entity type: ${entry.entityType}',
          );
      }
    } on NetworkException catch (e) {
      return SyncResult.retry(e.message);
    } on ServerException catch (e) {
      return SyncResult.permanentFailure(e.message);
    } catch (e) {
      return SyncResult.permanentFailure(e.toString());
    }
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  /// Checks whether the local row in [table] with [id] was modified after
  /// the sync entry was created.
  Future<bool> _isLocalModifiedAfter(
    String table,
    String id,
    DateTime entryCreatedAt,
  ) async {
    final db = await _localDatabase.database;
    final rows = await db.query(
      table,
      columns: [CommonCols.updatedAt],
      where: '${CommonCols.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    final updatedAtStr = rows.first[CommonCols.updatedAt] as String?;
    if (updatedAtStr == null) return false;
    final updatedAt = DateTime.tryParse(updatedAtStr);
    if (updatedAt == null) return false;
    return updatedAt.isAfter(entryCreatedAt);
  }

  /// Reconciles a server-returned [ClassModel] into the local DB.
  /// If the local row was modified after [entry.createdAt], data fields are
  /// **not** overwritten so newer local changes are preserved.
  Future<void> _reconcileClass(
    SyncQueueEntry entry,
    ClassModel model,
  ) async {
    final localId = entry.payload['id'] as String? ?? model.id;

    // ID reconciliation: server may return a different ID for creates.
    if (model.id != localId) {
      final db = await _localDatabase.database;
      // Must update all FK child tables that reference classes.id BEFORE
      // updating the PK, because the schema only has ON DELETE CASCADE
      // (no ON UPDATE CASCADE). Updating the PK directly with foreign_keys=ON
      // would either raise a constraint violation or orphan child rows.
      await db.transaction((txn) async {
        await txn.update(
          DbTables.classParticipants,
          {ClassParticipantsCols.classId: model.id},
          where: '${ClassParticipantsCols.classId} = ?',
          whereArgs: [localId],
        );
        // Update any pending enrollment/removal queue entries that still
        // reference the old optimistic UUID in their class_id payload field,
        // otherwise those entries will 404 on the server when they sync.
        await txn.rawUpdate(
          "UPDATE ${DbTables.syncQueue}"
          " SET ${SyncQueueCols.payload} = json_replace(${SyncQueueCols.payload}, '\$.class_id', ?)"
          " WHERE ${SyncQueueCols.status} = '${SyncStatus.pending.dbValue}'"
          " AND json_extract(${SyncQueueCols.payload}, '\$.class_id') = ?",
          [model.id, localId],
        );
        await txn.update(
          DbTables.classes,
          {CommonCols.id: model.id},
          where: '${CommonCols.id} = ?',
          whereArgs: [localId],
        );
      });
    }

    final conflict = await _isLocalModifiedAfter(
      DbTables.classes,
      model.id,
      entry.createdAt,
    );

    if (!conflict) {
      final db = await _localDatabase.database;
      await db.update(
        DbTables.classes,
        {
          ClassesCols.title: model.title,
          ClassesCols.description: model.description,
          ClassesCols.teacherId: model.teacherId,
          ClassesCols.teacherUsername: model.teacherUsername,
          ClassesCols.teacherFullName: model.teacherFullName,
          ClassesCols.isAdvisory: model.isAdvisory ? 1 : 0,
          ClassesCols.termType: model.termType,
          CommonCols.updatedAt: model.updatedAt.toIso8601String(),
          CommonCols.syncStatus: SyncStatus.synced.dbValue,
        },
        where: '${CommonCols.id} = ?',
        whereArgs: [model.id],
      );
    } else {
      _log.warn(
        'Conflict detected for class ${model.id}; '
        'skipping overwrite to preserve newer local changes.',
      );
      final db = await _localDatabase.database;
      await db.update(
        DbTables.classes,
        {CommonCols.syncStatus: SyncStatus.synced.dbValue},
        where: '${CommonCols.id} = ?',
        whereArgs: [model.id],
      );
    }
  }

  // --------------------------------------------------------------------------
  // Class entity handlers
  // --------------------------------------------------------------------------

  Future<SyncResult> _handleClass(SyncQueueEntry entry) async {
    switch (entry.operation) {
      case SyncOperation.create:
        return await _handleClassCreate(entry);
      case SyncOperation.update:
        return await _handleClassUpdate(entry);
      case SyncOperation.delete:
        return await _handleClassDelete(entry);
      case SyncOperation.addEnrollment:
        return await _handleAddEnrollment(entry);
      case SyncOperation.removeEnrollment:
        return await _handleRemoveEnrollment(entry);
      default:
        return SyncResult.permanentFailure(
          'Unsupported class operation: ${entry.operation}',
        );
    }
  }

  Future<SyncResult> _handleClassCreate(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final model = await _remote.createClass(
      title: payload['title'] as String,
      description: payload['description'] as String?,
      teacherId: payload['teacher_id'] as String?,
      isAdvisory: payload['is_advisory'] as bool? ?? false,
      idempotencyKey: entry.id,
    );
    await _reconcileClass(entry, model);
    return SyncResult.success(serverId: model.id);
  }

  Future<SyncResult> _handleClassUpdate(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final classId = payload['id'] as String;
    final model = await _remote.updateClass(
      classId: classId,
      title: payload['title'] as String?,
      description: payload['description'] as String?,
      teacherId: payload['teacher_id'] as String?,
      isAdvisory: payload['is_advisory'] as bool?,
      idempotencyKey: entry.id,
    );
    await _reconcileClass(entry, model);
    return const SyncResult.success();
  }

  Future<SyncResult> _handleClassDelete(SyncQueueEntry entry) async {
    final classId = entry.payload['id'] as String;
    await _remote.deleteClass(
      classId: classId,
      idempotencyKey: entry.id,
    );
    await _local.deleteClassLocally(classId: classId);
    return const SyncResult.success();
  }

  // --------------------------------------------------------------------------
  // Enrollment handlers
  // --------------------------------------------------------------------------

  Future<SyncResult> _handleAddEnrollment(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final classId = payload['class_id'] as String;
    final studentId = payload['student_id'] as String;
    final localEnrollmentId = payload['local_enrollment_id'] as String?;

    final participant = await _remote.addStudent(
      classId: classId,
      studentId: studentId,
      idempotencyKey: entry.id,
    );

    final db = await _localDatabase.database;

    // Reconcile participant ID if server returned a different one.
    final serverParticipantId = participant.id;
    if (localEnrollmentId != null &&
        serverParticipantId != localEnrollmentId) {
      await db.update(
        DbTables.classParticipants,
        {
          CommonCols.id: serverParticipantId,
          CommonCols.syncStatus: SyncStatus.synced.dbValue,
        },
        where: '${CommonCols.id} = ?',
        whereArgs: [localEnrollmentId],
      );
    } else if (localEnrollmentId != null) {
      await db.update(
        DbTables.classParticipants,
        {CommonCols.syncStatus: SyncStatus.synced.dbValue},
        where: '${CommonCols.id} = ?',
        whereArgs: [localEnrollmentId],
      );
    }

    // Upsert the student returned by the server into the users table.
    // Use UPDATE-or-INSERT instead of REPLACE to avoid triggering
    // ON DELETE CASCADE on class_participants.
    final student = participant.student;
    final existingUser = await db.query(
      DbTables.users,
      columns: [CommonCols.id],
      where: '${CommonCols.id} = ?',
      whereArgs: [student.id],
      limit: 1,
    );

    if (existingUser.isNotEmpty) {
      await db.update(
        DbTables.users,
        {
          UsersCols.username: student.username,
          UsersCols.firstName: student.firstName,
          UsersCols.lastName: student.lastName,
          UsersCols.role: student.role,
          UsersCols.accountStatus: student.accountStatus,
          CommonCols.updatedAt: DateTime.now().toIso8601String(),
          CommonCols.syncStatus: SyncStatus.synced.dbValue,
        },
        where: '${CommonCols.id} = ?',
        whereArgs: [student.id],
      );
    } else {
      await db.insert(
        DbTables.users,
        {
          CommonCols.id: student.id,
          UsersCols.username: student.username,
          UsersCols.firstName: student.firstName,
          UsersCols.lastName: student.lastName,
          UsersCols.role: student.role,
          UsersCols.accountStatus: student.accountStatus,
          CommonCols.createdAt: student.createdAt.toIso8601String(),
          CommonCols.updatedAt: DateTime.now().toIso8601String(),
          CommonCols.syncStatus: SyncStatus.synced.dbValue,
        },
      );
    }

    return const SyncResult.success();
  }

  Future<SyncResult> _handleRemoveEnrollment(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final classId = payload['class_id'] as String;
    final studentId = payload['student_id'] as String;

    await _remote.removeStudent(
      classId: classId,
      studentId: studentId,
      idempotencyKey: entry.id,
    );

    final db = await _localDatabase.database;
    await db.update(
      DbTables.classParticipants,
      {CommonCols.syncStatus: SyncStatus.synced.dbValue},
      where:
          '${ClassParticipantsCols.classId} = ? AND ${ClassParticipantsCols.userId} = ?',
      whereArgs: [classId, studentId],
    );

    return const SyncResult.success();
  }
}
