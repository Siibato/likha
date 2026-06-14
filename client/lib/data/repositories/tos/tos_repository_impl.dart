import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/data/datasources/remote/tos/tos_remote_datasource.dart';
import 'package:likha/data/models/tos/melcs_model.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';
import 'operations/tos.dart' as ops;

class TosRepositoryImpl implements TosRepository {
  final TosRemoteDataSource _remoteDataSource;
  final TosLocalDataSource _localDataSource;
  final SyncQueue _syncQueue;
  final DataEventBus _dataEventBus;

  TosRepositoryImpl({
    required TosRemoteDataSource remoteDataSource,
    required TosLocalDataSource localDataSource,
    required SyncQueue syncQueue,
    required DataEventBus dataEventBus,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _syncQueue = syncQueue,
        _dataEventBus = dataEventBus;

  @override
  ResultFuture<TableOfSpecifications> createTos({
    required String classId,
    required Map<String, dynamic> data,
  }) =>
      ops.createTos(
        _localDataSource,
        _remoteDataSource,
        _syncQueue,
        classId: classId,
        data: data,
      );

  @override
  ResultFuture<TableOfSpecifications> updateTos({
    required String tosId,
    required Map<String, dynamic> data,
  }) =>
      ops.updateTos(
        _localDataSource,
        _syncQueue,
        tosId: tosId,
        data: data,
      );

  @override
  ResultVoid deleteTos({required String tosId}) =>
      ops.deleteTos(
        _localDataSource,
        _syncQueue,
        tosId: tosId,
      );

  @override
  ResultFuture<List<TableOfSpecifications>> getTosList({
    required String classId,
  }) =>
      ops.getTosList(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        classId: classId,
      );

  @override
  ResultFuture<(TableOfSpecifications, List<TosCompetency>)> getTosDetail({
    required String tosId,
  }) =>
      ops.getTosDetail(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        tosId: tosId,
      );

  @override
  ResultFuture<List<MelcEntryModel>> searchMelcs({
    String? subject,
    String? gradeLevel,
    int? gradingPeriodNumber,
    String? query,
    int limit = 30,
    int offset = 0,
    bool skipBackgroundRefresh = false,
  }) =>
      ops.searchMelcs(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        subject: subject,
        gradeLevel: gradeLevel,
        gradingPeriodNumber: gradingPeriodNumber,
        query: query,
        limit: limit,
        offset: offset,
        skipBackgroundRefresh: skipBackgroundRefresh,
      );

  @override
  ResultFuture<TosCompetency> addCompetency({
    required String tosId,
    required Map<String, dynamic> data,
  }) =>
      ops.addCompetency(
        _localDataSource,
        _syncQueue,
        tosId: tosId,
        data: data,
      );

  @override
  ResultFuture<TosCompetency> updateCompetency({
    required String competencyId,
    required Map<String, dynamic> data,
  }) =>
      ops.updateCompetency(
        _localDataSource,
        _syncQueue,
        competencyId: competencyId,
        data: data,
      );

  @override
  ResultVoid deleteCompetency({required String competencyId}) =>
      ops.deleteCompetency(
        _localDataSource,
        _syncQueue,
        competencyId: competencyId,
      );

  @override
  ResultFuture<List<TosCompetency>> bulkAddCompetencies({
    required String tosId,
    required List<Map<String, dynamic>> competencies,
  }) =>
      ops.bulkAddCompetencies(
        _localDataSource,
        _syncQueue,
        tosId: tosId,
        competencies: competencies,
      );
}
