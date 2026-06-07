import 'package:likha/data/models/tos/tos_model.dart';
import 'package:likha/data/models/tos/melcs_model.dart';
import '../tos_local_datasource_base.dart';
import 'operations/query/get_tos_by_class.dart';
import 'operations/query/get_tos_by_id.dart';
import 'operations/query/get_competencies_by_tos.dart';
import 'operations/query/get_competency_by_id.dart';
import 'operations/query/search_melcs.dart';
import 'operations/query/seed_melcs_if_empty.dart';

mixin TosQueryMixin on TosLocalDataSourceBase {
  @override
  Future<List<TosModel>> getTosByClass(String classId) async {
    return getTosByClassOp(localDatabase, classId);
  }

  @override
  Future<TosModel?> getTosById(String tosId) async {
    return getTosByIdOp(localDatabase, tosId);
  }

  @override
  Future<List<CompetencyModel>> getCompetenciesByTos(String tosId) async {
    return getCompetenciesByTosOp(localDatabase, tosId);
  }

  @override
  Future<CompetencyModel?> getCompetencyById(String competencyId) async {
    return getCompetencyByIdOp(localDatabase, competencyId);
  }

  @override
  Future<List<MelcEntryModel>> searchMelcs({
    String? subject,
    String? gradeLevel,
    int? gradingPeriodNumber,
    String? query,
    int limit = 30,
    int offset = 0,
  }) async {
    return searchMelcsOp(
      localDatabase,
      subject: subject,
      gradeLevel: gradeLevel,
      gradingPeriodNumber: gradingPeriodNumber,
      query: query,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<void> seedMelcsIfEmpty() async {
    return seedMelcsIfEmptyOp(localDatabase);
  }
}
