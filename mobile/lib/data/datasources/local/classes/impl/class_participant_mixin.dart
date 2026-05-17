import 'package:likha/data/models/auth/user_model.dart';
import '../class_local_datasource_base.dart';
import 'operations/participant/add_student_locally.dart';
import 'operations/participant/remove_student_locally.dart';
import 'operations/participant/get_participant_ids.dart';

mixin ClassParticipantMixin on ClassLocalDataSourceBase {
  @override
  Future<String> addStudentLocally({
    required String classId,
    required UserModel student,
  }) async {
    return addStudentLocallyOp(localDatabase, classId, student);
  }

  @override
  Future<void> removeStudentLocally({
    required String classId,
    required String studentId,
  }) async {
    return removeStudentLocallyOp(localDatabase, classId, studentId);
  }

  @override
  Future<Set<String>> getParticipantIds(String classId) async {
    return getParticipantIdsOp(localDatabase, classId);
  }
}
