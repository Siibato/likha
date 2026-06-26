import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/logging/sync_logger.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/sync/sync_result.dart';
import 'package:likha/data/datasources/local/auth/auth_local_datasource.dart';
import 'package:likha/data/datasources/remote/auth/auth_remote_datasource.dart';
import 'package:likha/data/models/auth/user_model.dart';

/// Sync handler for all [SyncEntityType.adminUser] operations.
///
/// Invoked by the outbound sync engine for each pending admin user queue entry.
/// Calls the corresponding [AuthRemoteDataSource] method and reconciles
/// the server response into the local DB.
class AuthSyncHandler {
  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final LocalDatabase _localDatabase;
  final SyncLogger _log;

  AuthSyncHandler(
    this._remote,
    this._local,
    this._localDatabase,
    this._log,
  );

  Future<SyncResult> handle(SyncQueueEntry entry) async {
    try {
      switch (entry.entityType) {
        case SyncEntityType.adminUser:
          return await _handleAdminUser(entry);
        default:
          return SyncResult.permanentFailure(
            'Unsupported auth entity type: ${entry.entityType}',
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

  /// Reconciles a server-returned [UserModel] into the local DB.
  /// If the local row was modified after [entry.createdAt], data fields are
  /// **not** overwritten so newer local changes are preserved.
  Future<void> _reconcileUser(
    SyncQueueEntry entry,
    UserModel model,
  ) async {
    final localId = entry.payload['id'] as String? ?? model.id;

    // ID reconciliation: server may return a different ID for creates.
    if (model.id != localId) {
      final db = await _localDatabase.database;
      await db.update(
        DbTables.users,
        {CommonCols.id: model.id},
        where: '${CommonCols.id} = ?',
        whereArgs: [localId],
      );
    }

    final conflict = await _isLocalModifiedAfter(
      DbTables.users,
      model.id,
      entry.createdAt,
    );

    if (!conflict) {
      final db = await _localDatabase.database;
      final existing = await db.query(
        DbTables.users,
        columns: [CommonCols.id],
        where: '${CommonCols.id} = ?',
        whereArgs: [model.id],
        limit: 1,
      );
      final data = {
        UsersCols.username: model.username,
        UsersCols.firstName: model.firstName,
        UsersCols.lastName: model.lastName,
        UsersCols.role: model.role,
        UsersCols.accountStatus: model.accountStatus,
        CommonCols.updatedAt:
            model.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        CommonCols.syncStatus: SyncStatus.synced.dbValue,
      };
      if (existing.isNotEmpty) {
        await db.update(
          DbTables.users,
          data,
          where: '${CommonCols.id} = ?',
          whereArgs: [model.id],
        );
      } else {
        await db.insert(
          DbTables.users,
          {
            CommonCols.id: model.id,
            ...data,
            CommonCols.createdAt:
                model.createdAt.toIso8601String(),
          },
        );
      }
    } else {
      _log.warn(
        'Conflict detected for user ${model.id}; '
        'skipping overwrite to preserve newer local changes.',
      );
      final db = await _localDatabase.database;
      await db.update(
        DbTables.users,
        {CommonCols.syncStatus: SyncStatus.synced.dbValue},
        where: '${CommonCols.id} = ?',
        whereArgs: [model.id],
      );
    }
  }

  // --------------------------------------------------------------------------
  // Admin user handlers
  // --------------------------------------------------------------------------

  Future<SyncResult> _handleAdminUser(SyncQueueEntry entry) async {
    switch (entry.operation) {
      case SyncOperation.create:
        return await _handleAdminUserCreate(entry);
      case SyncOperation.update:
        return await _handleAdminUserUpdate(entry);
      case SyncOperation.delete:
        return await _handleAdminUserDelete(entry);
      default:
        return SyncResult.permanentFailure(
          'Unsupported adminUser operation: ${entry.operation}',
        );
    }
  }

  Future<SyncResult> _handleAdminUserCreate(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final learnerDetails = payload['learner_details'] as Map<String, dynamic>?;
    final teacherDetails = payload['teacher_details'] as Map<String, dynamic>?;
    final model = await _remote.createAccount(
      id: payload['id'] as String?,
      username: payload['username'] as String,
      firstName: payload['first_name'] as String? ?? '',
      lastName: payload['last_name'] as String? ?? '',
      role: payload['role'] as String,
      learnerDetails: learnerDetails,
      teacherDetails: teacherDetails,
      idempotencyKey: entry.id,
    );
    await _reconcileUser(entry, model);
    return SyncResult.success(serverId: model.id);
  }

  Future<SyncResult> _handleAdminUserUpdate(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final action = payload['action'] as String?;

    switch (action) {
      case 'update':
        return await _handleAdminUserRegularUpdate(entry);
      case 'reset':
        return await _handleAdminUserReset(entry);
      case 'lock':
        return await _handleAdminUserLock(entry);
      default:
        return SyncResult.permanentFailure(
          'Unsupported adminUser update action: $action',
        );
    }
  }

  Future<SyncResult> _handleAdminUserRegularUpdate(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final userId = payload['id'] as String;
    final model = await _remote.updateAccount(
      userId: userId,
      firstName: payload['first_name'] as String?,
      lastName: payload['last_name'] as String?,
      role: payload['role'] as String?,
      idempotencyKey: entry.id,
    );
    await _reconcileUser(entry, model);
    return const SyncResult.success();
  }

  Future<SyncResult> _handleAdminUserReset(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final userId = payload['id'] as String;
    final model = await _remote.resetAccount(
      userId: userId,
      idempotencyKey: entry.id,
    );
    await _reconcileUser(entry, model);
    return const SyncResult.success();
  }

  Future<SyncResult> _handleAdminUserLock(SyncQueueEntry entry) async {
    final payload = entry.payload;
    final userId = payload['id'] as String;
    final locked = payload['locked'] as bool;
    final model = await _remote.lockAccount(
      userId: userId,
      locked: locked,
      reason: payload['reason'] as String?,
      idempotencyKey: entry.id,
    );
    await _reconcileUser(entry, model);
    return const SyncResult.success();
  }

  Future<SyncResult> _handleAdminUserDelete(SyncQueueEntry entry) async {
    final userId = entry.payload['id'] as String;
    await _remote.deleteAccount(
      userId: userId,
      idempotencyKey: entry.id,
    );
    await _local.deleteAccountLocally(userId);
    return const SyncResult.success();
  }
}
