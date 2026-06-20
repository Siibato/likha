import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/local/auth/auth_local_datasource.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/remote/auth/auth_remote_datasource.dart';
import 'package:likha/domain/auth/entities/activity_log.dart';
import 'package:likha/domain/auth/entities/check_username_result.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';
import 'package:likha/services/storage_service.dart';
import 'operations/auth.dart' as ops;

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final StorageService _storageService;
  final SyncQueue _syncQueue;
  final ClassLocalDataSource _classLocalDataSource;
  final AssignmentLocalDataSource _assignmentLocalDataSource;
  final AssessmentLocalDataSource _assessmentLocalDataSource;
  final LearningMaterialLocalDataSource _learningMaterialLocalDataSource;
  final GradingLocalDataSource _gradingLocalDataSource;
  final DataEventBus _dataEventBus;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    required StorageService storageService,
    required SyncQueue syncQueue,
    required ClassLocalDataSource classLocalDataSource,
    required AssignmentLocalDataSource assignmentLocalDataSource,
    required AssessmentLocalDataSource assessmentLocalDataSource,
    required LearningMaterialLocalDataSource learningMaterialLocalDataSource,
    required GradingLocalDataSource gradingLocalDataSource,
    required DataEventBus dataEventBus,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _storageService = storageService,
        _syncQueue = syncQueue,
        _classLocalDataSource = classLocalDataSource,
        _assignmentLocalDataSource = assignmentLocalDataSource,
        _assessmentLocalDataSource = assessmentLocalDataSource,
        _learningMaterialLocalDataSource = learningMaterialLocalDataSource,
        _gradingLocalDataSource = gradingLocalDataSource,
        _dataEventBus = dataEventBus;

  @override
  ResultFuture<CheckUsernameResult> checkUsername({required String username}) =>
      ops.checkUsername(_remoteDataSource, username: username);

  @override
  ResultFuture<User> activateAccount({
    required String username,
    required String password,
    required String confirmPassword,
  }) =>
      ops.activateAccount(
        _remoteDataSource,
        username: username,
        password: password,
        confirmPassword: confirmPassword,
      );

  @override
  ResultFuture<User> login({
    required String username,
    required String password,
    String? deviceId,
  }) =>
      ops.login(
        _remoteDataSource,
        _localDataSource,
        _storageService,
        _syncQueue,
        _classLocalDataSource,
        _assignmentLocalDataSource,
        _assessmentLocalDataSource,
        _learningMaterialLocalDataSource,
        _gradingLocalDataSource,
        username: username,
        password: password,
        deviceId: deviceId,
      );

  @override
  ResultFuture<User> refreshToken() =>
      ops.refreshToken(_remoteDataSource, _storageService);

  @override
  ResultFuture<User> getCurrentUser() =>
      ops.getCurrentUser(
        _remoteDataSource,
        _localDataSource,
        _storageService,
        _dataEventBus,
      );

  @override
  ResultVoid logout() =>
      ops.logout(
        _remoteDataSource,
        _localDataSource,
        _storageService,
        _syncQueue,
        _classLocalDataSource,
        _assignmentLocalDataSource,
        _assessmentLocalDataSource,
        _learningMaterialLocalDataSource,
        _gradingLocalDataSource,
      );

  @override
  Future<bool> isAuthenticated() =>
      ops.isAuthenticated(_storageService);

  @override
  ResultFuture<MutationResult<User>> createAccount({
    required String username,
    required String fullName,
    required String role,
  }) =>
      ops.createAccount(
        _localDataSource,
        _syncQueue,
        username: username,
        fullName: fullName,
        role: role,
      );

  @override
  ResultFuture<List<User>> getAllAccounts({bool skipBackgroundRefresh = false}) =>
      ops.getAllAccounts(
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        _dataEventBus,
        skipBackgroundRefresh: skipBackgroundRefresh,
      );

  @override
  ResultFuture<MutationResult<User>> resetAccount({required String userId}) =>
      ops.resetAccount(
        _localDataSource,
        _syncQueue,
        userId: userId,
      );

  @override
  ResultFuture<MutationResult<User>> lockAccount({
    required String userId,
    required bool locked,
    String? reason,
  }) =>
      ops.lockAccount(
        _localDataSource,
        _syncQueue,
        userId: userId,
        locked: locked,
        reason: reason,
      );

  @override
  ResultFuture<MutationResult<User>> updateAccount({
    required String userId,
    String? fullName,
    String? role,
  }) =>
      ops.updateAccount(
        _localDataSource,
        _syncQueue,
        userId: userId,
        fullName: fullName,
        role: role,
      );

  @override
  ResultVoid deleteAccount({required String userId}) =>
      ops.deleteAccount(
        _localDataSource,
        _syncQueue,
        userId: userId,
      );

  @override
  ResultFuture<List<ActivityLog>> getActivityLogs({required String userId}) =>
      ops.getActivityLogs(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        userId: userId,
      );
}