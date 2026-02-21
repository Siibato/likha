import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/datasources/remote/sync_remote_datasource.dart';

/// Base class for repositories implementing offline-first pattern with
/// manifest-driven sync
///
/// Repositories extending this class will:
/// 1. Prefer local database for reads
/// 2. Fall back to remote if offline or data not cached
/// 3. Queue writes offline and sync when online
/// 4. Handle conflict resolution server-side
abstract class BaseOfflineRepository {
  final LocalDatabase localDatabase;
  final SyncRemoteDataSource remoteDataSource;

  BaseOfflineRepository({
    required this.localDatabase,
    required this.remoteDataSource,
  });

  /// Online-first pattern: try remote, fallback to local
  /// Returns data and indicates if it was from local cache
  Future<(T data, bool isFromLocal)> getDataOnlineFirst<T>({
    required Future<T> Function() fetchRemote,
    required Future<T?> Function() fetchLocal,
  }) async {
    try {
      // Try remote first
      try {
        final data = await fetchRemote();
        return (data, false); // From remote
      } catch (e) {
        // Remote failed, try local fallback
        final localData = await fetchLocal();
        if (localData != null) {
          return (localData, true); // From local cache
        }
        rethrow;
      }
    } catch (e) {
      // Last resort: try local only
      final localData = await fetchLocal();
      if (localData != null) {
        return (localData, true); // From local cache
      }
      rethrow;
    }
  }

  /// Queue a mutation (create/update/delete) for offline sync
  /// Returns immediately with local ID, syncs in background when online
  Future<String> queueMutation({
    required String entityType,
    required String operation, // "create", "update", "delete"
    required Map<String, dynamic> payload,
    required Future<String?> Function() getLocalId,
    required Future<void> Function() persistLocally,
  }) async {
    // Generate local ID for tracking
    final localId = await getLocalId();

    // Persist change locally first (offline-first)
    await persistLocally();

    // TODO: Queue for sync - requires LocalDatabase.addSyncOperation
    // await localDatabase.addSyncOperation(
    //   localId: localId ?? '',
    //   entityType: entityType,
    //   operation: operation,
    //   payload: payload,
    // );

    return localId ?? '';
  }

  /// Check if entitlements have been synced
  /// Used to determine if user needs to sync before accessing data
  Future<bool> hasValidManifest() async {
    // TODO: Check manifest validity - requires LocalDatabase.hasValidManifest
    // return await localDatabase.hasValidManifest();
    return false;
  }

  /// Clear all cached data for this repository
  /// Used when user logs out or needs fresh sync
  Future<void> clearCache();
}
