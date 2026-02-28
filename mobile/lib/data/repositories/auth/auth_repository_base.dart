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
    required this.classLocalDataSource,
    required this.assignmentLocalDataSource,
    required this.assessmentLocalDataSource,
    required this.learningMaterialLocalDataSource,
  });

  /// Clear all user-specific cached data when switching users.
  /// Called when a different user logs in to prevent data leakage.
  Future<void> clearAllUserData() async {
    try {
      await Future.wait([
        classLocalDataSource.clearAllCache(),
        assignmentLocalDataSource.clearAllCache(),
        assessmentLocalDataSource.clearAllCache(),
        learningMaterialLocalDataSource.clearAllCache(),
      ]);
    } catch (e) {
      // Best-effort cache clearing — don't fail login if cache clearing fails
    }
  }
}