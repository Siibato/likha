import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'learning_material_local_datasource.dart';

abstract class LearningMaterialLocalDataSourceBase
    implements LearningMaterialLocalDataSource {
  LocalDatabase get localDatabase;
  SyncQueue get syncQueue;
}