import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/tos/tos_model.dart';
import 'package:likha/data/models/tos/melcs_model.dart';
import 'operations/tos.dart' as ops;

abstract class TosLocalDataSource {
  // Cache (from sync)
  Future<void> cacheTosList(List<TosModel> tosList);
  Future<void> cacheCompetencies(String tosId, List<CompetencyModel> competencies);

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
  Future<void> saveTos(TosModel tos);
  Future<void> updateTosFields(String tosId, Map<String, dynamic> data);
  Future<void> softDeleteTos(String tosId);
  Future<void> saveCompetency(CompetencyModel competency);
  Future<void> updateCompetencyFields(String competencyId, Map<String, dynamic> data);
  Future<void> softDeleteCompetency(String competencyId);
  Future<void> bulkSaveCompetencies(List<CompetencyModel> competencies);
}

class TosLocalDataSourceImpl implements TosLocalDataSource {
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
  Future<void> saveTos(TosModel tos) =>
      ops.saveTos(localDatabase, syncQueue, tos);

  @override
  Future<void> updateTosFields(
    String tosId,
    Map<String, dynamic> data,
  ) =>
      ops.updateTosFields(localDatabase, syncQueue, tosId, data);

  @override
  Future<void> softDeleteTos(String tosId) =>
      ops.softDeleteTos(localDatabase, syncQueue, tosId);

  @override
  Future<void> saveCompetency(CompetencyModel competency) =>
      ops.saveCompetency(localDatabase, syncQueue, competency);

  @override
  Future<void> updateCompetencyFields(
    String competencyId,
    Map<String, dynamic> data,
  ) =>
      ops.updateCompetencyFields(localDatabase, syncQueue, competencyId, data);

  @override
  Future<void> softDeleteCompetency(String competencyId) =>
      ops.softDeleteCompetency(localDatabase, syncQueue, competencyId);

  @override
  Future<void> bulkSaveCompetencies(List<CompetencyModel> competencies) =>
      ops.bulkSaveCompetencies(localDatabase, syncQueue, competencies);
}
