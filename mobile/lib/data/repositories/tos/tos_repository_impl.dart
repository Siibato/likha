import 'package:likha/data/repositories/tos/tos_repository_base.dart';
import 'mixins/tos_query_mixin.dart';
import 'mixins/tos_crud_mixin.dart';
import 'mixins/tos_competency_mixin.dart';

class TosRepositoryImpl extends TosRepositoryBase
    with TosQueryMixin, TosCrudMixin, TosCompetencyMixin {
  TosRepositoryImpl({
    required super.remoteDataSource,
    required super.localDataSource,
    required super.serverReachabilityService,
    required super.syncQueue,
  });
}
