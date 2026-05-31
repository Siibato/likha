import '../grading_local_datasource_base.dart';
import 'operations/clear/clear_all_cache.dart';

mixin GradingClearMixin on GradingLocalDataSourceBase {
  @override
  Future<void> clearAllCache() async {
    return clearAllCacheOp(localDatabase);
  }
}
