import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';

ResultVoid saveAnswers(
  AssessmentRepositoryBase base, {
  required String submissionId,
  required List<Map<String, dynamic>> answers,
}) async {
  try {
    if (!base.serverReachabilityService.isServerReachable) {
      await base.localDataSource.saveAnswers(
        submissionId: submissionId,
        answersJson: jsonEncode(answers),
      );
      return const Right(null);
    }

    await base.remoteDataSource.saveAnswers(
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
