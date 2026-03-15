import 'package:likha/data/repositories/learning_materials/learning_material_repository_base.dart';
import 'mixins/learning_material_crud_mixin.dart';
import 'mixins/learning_material_query_mixin.dart';
import 'mixins/learning_material_file_mixin.dart';

class LearningMaterialRepositoryImpl extends LearningMaterialRepositoryBase
    with
        LearningMaterialCrudMixin,
        LearningMaterialQueryMixin,
        LearningMaterialFileMixin {
  LearningMaterialRepositoryImpl({
    required super.remoteDataSource,
    required super.localDataSource,
    required super.validationService,
    required super.connectivityService,
    required super.syncQueue,
    required super.serverReachabilityService,
    required super.storageService,
    required super.dataEventBus,
  });
}