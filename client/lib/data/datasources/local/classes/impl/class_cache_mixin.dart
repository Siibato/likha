import 'package:likha/data/models/classes/class_detail_model.dart';
import 'package:likha/data/models/classes/class_model.dart';
import '../class_local_datasource_base.dart';
import 'operations/cache/cache_classes.dart';
import 'operations/cache/cache_student_participation.dart';
import 'operations/cache/cache_class_detail.dart';
import 'operations/cache/clear_all_cache.dart';

mixin ClassCacheMixin on ClassLocalDataSourceBase {
  @override
  Future<void> cacheClasses(List<ClassModel> classes) async {
    return cacheClassesOp(localDatabase, classes);
  }

  @override
  Future<void> cacheStudentParticipation({
    required String classId,
    required String userId,
    required DateTime joinedAt,
  }) async {
    return cacheStudentParticipationOp(localDatabase, classId, userId, joinedAt);
  }

  @override
  Future<void> cacheClassDetail(ClassDetailModel classDetail) async {
    return cacheClassDetailOp(localDatabase, classDetail);
  }

  @override
  Future<void> clearAllCache() async {
    return clearAllCacheOp(localDatabase);
  }
}
