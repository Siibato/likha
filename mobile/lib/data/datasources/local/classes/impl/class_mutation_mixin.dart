import 'package:likha/data/models/classes/class_model.dart';
import '../class_local_datasource_base.dart';
import 'operations/mutation/create_class_locally.dart';
import 'operations/mutation/update_class_locally.dart';

mixin ClassMutationMixin on ClassLocalDataSourceBase {
  @override
  Future<ClassModel> createClassLocally({
    required String title,
    required String description,
    required String teacherId,
    required String teacherUsername,
    required String teacherFullName,
  }) async {
    return createClassLocallyOp(localDatabase, syncQueue, title, description, teacherId, teacherUsername, teacherFullName);
  }

  @override
  Future<void> updateClassLocally({
    required String classId,
    required String title,
    required String description,
    bool? isAdvisory,
  }) async {
    return updateClassLocallyOp(localDatabase, syncQueue, classId, title, description, isAdvisory);
  }
}
