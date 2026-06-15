import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'grading_local_datasource.dart';

abstract class GradingLocalDataSourceBase implements GradingLocalDataSource {
  LocalDatabase get localDatabase;
  SyncQueue get syncQueue;
}
