import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/local/auth/auth_local_datasource.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/remote/auth_remote_datasource.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';
import 'package:likha/services/storage_service.dart';

abstract class AuthRepositoryBase extends AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final ServerReachabilityService serverReachabilityService;
  final StorageService storageService;
  final SyncQueue syncQueue;
  final LocalDatabase localDatabase;
  final ClassLocalDataSource classLocalDataSource;
  final AssignmentLocalDataSource assignmentLocalDataSource;
  final AssessmentLocalDataSource assessmentLocalDataSource;
  final LearningMaterialLocalDataSource learningMaterialLocalDataSource;

  AuthRepositoryBase({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.serverReachabilityService,
    required this.storageService,
    required this.syncQueue,
    required this.localDatabase,
    required this.classLocalDataSource,
    required this.assignmentLocalDataSource,
    required this.assessmentLocalDataSource,
    required this.learningMaterialLocalDataSource,
  });

  /// Clear all user-specific cached data when switching users or logging out.
  /// Called when a different user logs in or when logging out to prevent data leakage.
  Future<void> clearAllUserData() async {
    try {
      await Future.wait([
        classLocalDataSource.clearAllCache(),
        assignmentLocalDataSource.clearAllCache(),
        assessmentLocalDataSource.clearAllCache(),
        learningMaterialLocalDataSource.clearAllCache(),
        localDataSource.clearAllCache(),
        syncQueue.clear(),
      ]);

      // Clear sync metadata (last_sync_at and data_expiry_at) to prevent user B from inheriting
      // user A's delta sync cursor. Preserve device_id as it should persist across user sessions.
      try {
        final db = await localDatabase.database;
        await db.delete(
          'sync_metadata',
          where: 'key IN (?, ?)',
          whereArgs: ['last_sync_at', 'data_expiry_at'],
        );
      } catch (e) {
        // Best-effort sync metadata clearing
      }
    } catch (e) {
      // Best-effort cache clearing — don't fail login/logout if cache clearing fails
    }
  }
}