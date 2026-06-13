import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';

ResultVoid saveAnswers(
  ServerReachabilityService serverReachabilityService,
AssessmentLocalDataSource localDataSource,
AssessmentRemoteDataSource remoteDataSource, {
  required String submissionId,
  required List<Map<String, dynamic>> answers,
}) async {
  try {
    if (!serverReachabilityService.isServerReachable) {
      await localDataSource.saveAnswers(
        submissionId: submissionId,
        answersJson: jsonEncode(answers),
      );
      return const Right(null);
    }

    await remoteDataSource.saveAnswers(
        submissionId: submissionId, answers: answers);
    return const Right(null);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
