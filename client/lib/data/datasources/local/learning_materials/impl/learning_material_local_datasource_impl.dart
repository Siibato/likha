import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/security/encryption_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import '../learning_material_local_datasource_base.dart';
import 'learning_material_cache_mixin.dart';
import 'learning_material_mutation_mixin.dart';
import 'learning_material_query_mixin.dart';

class LearningMaterialLocalDataSourceImpl
    extends LearningMaterialLocalDataSourceBase
    with
        LearningMaterialQueryMixin,
        LearningMaterialCacheMixin,
        LearningMaterialMutationMixin {
  @override
  final LocalDatabase localDatabase;

  @override
  final SyncQueue syncQueue;

  @override
  final EncryptionService enc;

  LearningMaterialLocalDataSourceImpl(this.localDatabase, this.syncQueue, this.enc);
}