import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/data/datasources/remote/tos/tos_remote_datasource.dart';
import 'package:likha/data/models/tos/melcs_model.dart';

ResultFuture<List<MelcEntryModel>> searchMelcs(
  ServerReachabilityService serverReachabilityService,
  TosLocalDataSource localDataSource,
  TosRemoteDataSource remoteDataSource, {
  String? subject,
  String? gradeLevel,
  int? gradingPeriodNumber,
  String? query,
  int limit = 30,
  int offset = 0,
}) async {
  try {
    // Try remote first
    if (serverReachabilityService.isServerReachable) {
      final remote = await remoteDataSource.searchMelcs(
        subject: subject,
        gradeLevel: gradeLevel,
        quarter: gradingPeriodNumber,
        query: query,
        limit: limit,
        offset: offset,
      );
      return Right(remote);
    }

    // Fallback to local
    final local = await localDataSource.searchMelcs(
      subject: subject,
      gradeLevel: gradeLevel,
      gradingPeriodNumber: gradingPeriodNumber,
      query: query,
      limit: limit,
      offset: offset,
    );
    return Right(local);
  } on ServerFailure catch (e) {
    return Left(e);
  } catch (e) {
    return Left(CacheFailure(e.toString()));
  }
}
