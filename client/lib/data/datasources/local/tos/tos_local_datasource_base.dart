import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'tos_local_datasource.dart';

abstract class TosLocalDataSourceBase implements TosLocalDataSource {
  LocalDatabase get localDatabase;
  SyncQueue get syncQueue;
}
