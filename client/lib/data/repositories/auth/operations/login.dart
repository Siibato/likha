import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/local/auth/auth_local_datasource.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/remote/auth/auth_remote_datasource.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/services/storage_service.dart';
import '_helpers.dart' as helpers;

ResultFuture<User> login(
  AuthRemoteDataSource remoteDataSource,
  AuthLocalDataSource localDataSource,
  StorageService storageService,
  SyncQueue syncQueue,
  ClassLocalDataSource classLocalDataSource,
  AssignmentLocalDataSource assignmentLocalDataSource,
  AssessmentLocalDataSource assessmentLocalDataSource,
  LearningMaterialLocalDataSource learningMaterialLocalDataSource,
  GradingLocalDataSource gradingLocalDataSource, {
  required String username,
  required String password,
  String? deviceId,
}) async {
  try {
    final result = await remoteDataSource.login(
      username: username,
      password: password,
      deviceId: deviceId,
    );

    // Detect user change and clear cache if a different user is logging in.
    final previousUserId = await storageService.getUserId();
    if (previousUserId != null && previousUserId != result.user.id) {
      await helpers.clearAllUserData(
        classLocalDataSource: classLocalDataSource,
        assignmentLocalDataSource: assignmentLocalDataSource,
        assessmentLocalDataSource: assessmentLocalDataSource,
        learningMaterialLocalDataSource: learningMaterialLocalDataSource,
        gradingLocalDataSource: gradingLocalDataSource,
        localDataSource: localDataSource,
        syncQueue: syncQueue,
        storageService: storageService,
        clearSyncQueue: true,
      );
    }

    unawaited(localDataSource.cacheCurrentUser(result.user));
    unawaited(storageService.saveUserRole(result.user.role));

    return Right(result.user);
  } on TooManyRequestsException catch (e) {
    return Left(TooManyRequestsFailure(e.message, remainingSeconds: e.remainingSeconds));
  } on InvalidCredentialsException catch (e) {
    RepoLogger.instance.log('Caught InvalidCredentialsException with attemptsRemaining: ${e.attemptsRemaining}');
    return Left(InvalidCredentialsFailure(e.message, attemptsRemaining: e.attemptsRemaining));
  } on ActivationRequiredException catch (e) {
    return Left(ActivationRequiredFailure(
      e.message,
      username: e.username,
      fullName: e.fullName,
    ));
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on UnauthorizedException catch (e) {
    return Left(UnauthorizedFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
