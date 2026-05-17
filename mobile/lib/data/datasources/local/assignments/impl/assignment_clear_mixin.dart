import '../assignment_local_datasource_base.dart';
import 'operations/clear/clear_all_cache.dart';

mixin AssignmentClearMixin on AssignmentLocalDataSourceBase {
  @override
  Future<void> clearAllCache() async {
    return clearAllCacheOp(localDatabase);
  }
}