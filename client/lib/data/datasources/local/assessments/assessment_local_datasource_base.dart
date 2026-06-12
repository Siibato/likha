import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'assessment_local_datasource.dart';

abstract class AssessmentLocalDataSourceBase implements AssessmentLocalDataSource {
  LocalDatabase get localDatabase;
  SyncQueue get syncQueue;
}