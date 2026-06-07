import 'package:likha/data/models/tos/tos_model.dart';
import '../tos_local_datasource_base.dart';
import 'operations/mutation/save_tos.dart';
import 'operations/mutation/update_tos_fields.dart';
import 'operations/mutation/soft_delete_tos.dart';
import 'operations/mutation/save_competency.dart';
import 'operations/mutation/update_competency_fields.dart';
import 'operations/mutation/soft_delete_competency.dart';
import 'operations/mutation/bulk_save_competencies.dart';

mixin TosMutationMixin on TosLocalDataSourceBase {
  @override
  Future<void> saveTos(TosModel tos) async {
    return saveTosOp(localDatabase, syncQueue, tos);
  }

  @override
  Future<void> updateTosFields(
    String tosId,
    Map<String, dynamic> data,
  ) async {
    return updateTosFieldsOp(localDatabase, syncQueue, tosId, data);
  }

  @override
  Future<void> softDeleteTos(String tosId) async {
    return softDeleteTosOp(localDatabase, syncQueue, tosId);
  }

  @override
  Future<void> saveCompetency(CompetencyModel competency) async {
    return saveCompetencyOp(localDatabase, syncQueue, competency);
  }

  @override
  Future<void> updateCompetencyFields(
    String competencyId,
    Map<String, dynamic> data,
  ) async {
    return updateCompetencyFieldsOp(localDatabase, syncQueue, competencyId, data);
  }

  @override
  Future<void> softDeleteCompetency(String competencyId) async {
    return softDeleteCompetencyOp(localDatabase, syncQueue, competencyId);
  }

  @override
  Future<void> bulkSaveCompetencies(List<CompetencyModel> competencies) async {
    return bulkSaveCompetenciesOp(localDatabase, syncQueue, competencies);
  }
}
