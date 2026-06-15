import 'package:likha/data/models/tos/tos_model.dart';
import '../tos_local_datasource_base.dart';
import 'operations/cache/cache_tos_list.dart';
import 'operations/cache/cache_competencies.dart';

mixin TosCacheMixin on TosLocalDataSourceBase {
  @override
  Future<void> cacheTosList(List<TosModel> tosList) async {
    return cacheTosListOp(localDatabase, tosList);
  }

  @override
  Future<void> cacheCompetencies(
    String tosId,
    List<CompetencyModel> competencies,
  ) async {
    return cacheCompetenciesOp(localDatabase, tosId, competencies);
  }
}
