import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/security/encryption_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'assignment_local_datasource.dart';

abstract class AssignmentLocalDataSourceBase implements AssignmentLocalDataSource {
  LocalDatabase get localDatabase;
  SyncQueue get syncQueue;
  EncryptionService get enc;
}