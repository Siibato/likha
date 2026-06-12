import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'class_local_datasource.dart';

abstract class ClassLocalDataSourceBase implements ClassLocalDataSource {
  LocalDatabase get localDatabase;
  SyncQueue get syncQueue;
}