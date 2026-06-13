import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/local/auth/auth_local_datasource.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/remote/auth/auth_remote_datasource.dart';
import 'package:likha/services/storage_service.dart';
import '_helpers.dart' as helpers;

ResultVoid logout(
  AuthRemoteDataSource remoteDataSource,
  AuthLocalDataSource localDataSource,
  StorageService storageService,
  SyncQueue syncQueue,
  ClassLocalDataSource classLocalDataSource,
  AssignmentLocalDataSource assignmentLocalDataSource,
  AssessmentLocalDataSource assessmentLocalDataSource,
  LearningMaterialLocalDataSource learningMaterialLocalDataSource,
  GradingLocalDataSource gradingLocalDataSource,
) async {
  try {
    final token = await storageService.getRefreshToken();
    if (token != null) {
      await remoteDataSource.logout(token);
    }
    await helpers.clearAllUserData(
      classLocalDataSource: classLocalDataSource,
      assignmentLocalDataSource: assignmentLocalDataSource,
      assessmentLocalDataSource: assessmentLocalDataSource,
      learningMaterialLocalDataSource: learningMaterialLocalDataSource,
      gradingLocalDataSource: gradingLocalDataSource,
      localDataSource: localDataSource,
      syncQueue: syncQueue,
      storageService: storageService,
    );
    return const Right(null);
  } on ServerException catch (e) {
    await helpers.clearAllUserData(
      classLocalDataSource: classLocalDataSource,
      assignmentLocalDataSource: assignmentLocalDataSource,
      assessmentLocalDataSource: assessmentLocalDataSource,
      learningMaterialLocalDataSource: learningMaterialLocalDataSource,
      gradingLocalDataSource: gradingLocalDataSource,
      localDataSource: localDataSource,
      syncQueue: syncQueue,
      storageService: storageService,
    );
    return Left(ServerFailure(e.message));
  } on NetworkException catch (e) {
    await helpers.clearAllUserData(
      classLocalDataSource: classLocalDataSource,
      assignmentLocalDataSource: assignmentLocalDataSource,
      assessmentLocalDataSource: assessmentLocalDataSource,
      learningMaterialLocalDataSource: learningMaterialLocalDataSource,
      gradingLocalDataSource: gradingLocalDataSource,
      localDataSource: localDataSource,
      syncQueue: syncQueue,
      storageService: storageService,
    );
    return Left(NetworkFailure(e.message));
  } catch (e) {
    await helpers.clearAllUserData(
      classLocalDataSource: classLocalDataSource,
      assignmentLocalDataSource: assignmentLocalDataSource,
      assessmentLocalDataSource: assessmentLocalDataSource,
      learningMaterialLocalDataSource: learningMaterialLocalDataSource,
      gradingLocalDataSource: gradingLocalDataSource,
      localDataSource: localDataSource,
      syncQueue: syncQueue,
      storageService: storageService,
    );
    return Left(ServerFailure(e.toString()));
  }
}
