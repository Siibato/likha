import 'package:likha/data/models/classes/class_detail_model.dart';
import 'package:likha/data/models/classes/class_model.dart';
import '../class_local_datasource_base.dart';
import 'operations/query/get_cached_classes.dart';
import 'operations/query/get_cached_classes_for_user.dart';
import 'operations/query/get_cached_class_detail.dart';
import 'operations/query/build_class_detail_from_participants.dart';

mixin ClassQueryMixin on ClassLocalDataSourceBase {
  @override
  Future<List<ClassModel>> getCachedClasses({String? teacherId}) async {
    return getCachedClassesOp(localDatabase, enc, teacherId);
  }

  @override
  Future<List<ClassModel>> getCachedClassesForUser(String userId) async {
    return getCachedClassesForUserOp(localDatabase, enc, userId);
  }

  @override
  Future<ClassDetailModel> getCachedClassDetail(String classId) async {
    return getCachedClassDetailOp(localDatabase, enc, classId);
  }

  @override
  Future<ClassDetailModel?> buildClassDetailFromParticipants(String classId) async {
    return buildClassDetailFromParticipantsOp(localDatabase, enc, classId);
  }
}
