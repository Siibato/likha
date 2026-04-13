import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'auth_local_datasource.dart';

abstract class AuthLocalDataSourceBase implements AuthLocalDataSource {
  LocalDatabase get localDatabase;
  SyncQueue get syncQueue;
}