import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/tos/tos_model.dart';
import 'package:likha/data/models/tos/melcs_model.dart';
import 'operations/tos.dart' as ops;

abstract class TosLocalDataSource {
  LocalDatabase get localDatabase;

  // Cache (from sync)
  Future<void> cacheTosList(List<TosModel> tosList);
  Future<void> cacheCompetencies(String tosId, List<CompetencyModel> competencies);
  Future<void> cacheMelcs(List<MelcEntryModel> melcs);

  // Queries
  Future<List<TosModel>> getTosByClass(String classId);
  Future<TosModel?> getTosById(String tosId);
  Future<List<CompetencyModel>> getCompetenciesByTos(String tosId);
  Future<CompetencyModel?> getCompetencyById(String competencyId);
  Future<List<MelcEntryModel>> searchMelcs({
    String? subject,
    String? gradeLevel,
    int? gradingPeriodNumber,
    String? query,
    int limit = 30,
    int offset = 0,
  });
  Future<void> seedMelcsIfEmpty();

  // Mutations (offline-first)
  Future<void> saveTos(TosModel tos, {Transaction? txn});
  Future<void> updateTosFields(String tosId, Map<String, dynamic> data, {Transaction? txn});
  Future<void> softDeleteTos(String tosId, {Transaction? txn});
  Future<void> saveCompetency(CompetencyModel competency, {Transaction? txn});
  Future<void> updateCompetencyFields(String competencyId, Map<String, dynamic> data, {Transaction? txn});
  Future<void> softDeleteCompetency(String competencyId, {Transaction? txn});
  Future<void> bulkSaveCompetencies(List<CompetencyModel> competencies, {Transaction? txn});
}

class TosLocalDataSourceImpl implements TosLocalDataSource {
  @override
  final LocalDatabase localDatabase;
  final SyncQueue syncQueue;

  TosLocalDataSourceImpl(this.localDatabase, this.syncQueue);

  @override
  Future<void> cacheTosList(List<TosModel> tosList) =>
      ops.cacheTosList(localDatabase, tosList);

  @override
  Future<void> cacheCompetencies(
    String tosId,
    List<CompetencyModel> competencies,
  ) =>
      ops.cacheCompetencies(localDatabase, tosId, competencies);

  @override
  Future<void> cacheMelcs(List<MelcEntryModel> melcs) =>
      ops.cacheMelcs(localDatabase, melcs);

  @override
  Future<List<TosModel>> getTosByClass(String classId) =>
      ops.getTosByClass(localDatabase, classId);

  @override
  Future<TosModel?> getTosById(String tosId) =>
      ops.getTosById(localDatabase, tosId);

  @override
  Future<List<CompetencyModel>> getCompetenciesByTos(String tosId) =>
      ops.getCompetenciesByTos(localDatabase, tosId);

  @override
  Future<CompetencyModel?> getCompetencyById(String competencyId) =>
      ops.getCompetencyById(localDatabase, competencyId);

  @override
  Future<List<MelcEntryModel>> searchMelcs({
    String? subject,
    String? gradeLevel,
    int? gradingPeriodNumber,
    String? query,
    int limit = 30,
    int offset = 0,
  }) =>
      ops.searchMelcs(
        localDatabase,
        subject: subject,
        gradeLevel: gradeLevel,
        gradingPeriodNumber: gradingPeriodNumber,
        query: query,
        limit: limit,
        offset: offset,
      );

  @override
  Future<void> seedMelcsIfEmpty() =>
      ops.seedMelcsIfEmpty(localDatabase);

  @override
  Future<void> saveTos(TosModel tos, {Transaction? txn}) =>
      ops.saveTos(localDatabase, syncQueue, tos, txn: txn);

  @override
  Future<void> updateTosFields(
    String tosId,
    Map<String, dynamic> data, {
    Transaction? txn,
  }) =>
      ops.updateTosFields(localDatabase, syncQueue, tosId, data, txn: txn);

  @override
  Future<void> softDeleteTos(String tosId, {Transaction? txn}) =>
      ops.softDeleteTos(localDatabase, syncQueue, tosId, txn: txn);

  @override
  Future<void> saveCompetency(CompetencyModel competency, {Transaction? txn}) =>
      ops.saveCompetency(localDatabase, syncQueue, competency, txn: txn);

  @override
  Future<void> updateCompetencyFields(
    String competencyId,
    Map<String, dynamic> data, {
    Transaction? txn,
  }) =>
      ops.updateCompetencyFields(localDatabase, syncQueue, competencyId, data, txn: txn);

  @override
  Future<void> softDeleteCompetency(String competencyId, {Transaction? txn}) =>
      ops.softDeleteCompetency(localDatabase, syncQueue, competencyId, txn: txn);

  @override
  Future<void> bulkSaveCompetencies(List<CompetencyModel> competencies, {Transaction? txn}) =>
      ops.bulkSaveCompetencies(localDatabase, syncQueue, competencies, txn: txn);
}
