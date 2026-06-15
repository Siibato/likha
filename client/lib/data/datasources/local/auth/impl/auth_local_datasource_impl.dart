import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import '../auth_local_datasource_base.dart';
import 'auth_cache_mixin.dart';
import 'auth_query_mixin.dart';

class AuthLocalDataSourceImpl extends AuthLocalDataSourceBase
    with AuthQueryMixin, AuthCacheMixin {
  @override
  final LocalDatabase localDatabase;

  @override
  final SyncQueue syncQueue;

  AuthLocalDataSourceImpl(this.localDatabase, this.syncQueue);
}