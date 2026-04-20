import 'package:likha/data/models/tos/tos_model.dart';
import 'package:likha/data/models/tos/melcs_model.dart';

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
