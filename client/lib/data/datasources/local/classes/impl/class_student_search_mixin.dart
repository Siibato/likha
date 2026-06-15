import 'package:likha/data/models/auth/user_model.dart';
import '../class_local_datasource_base.dart';
import 'operations/student_search/get_student_by_id.dart';
import 'operations/student_search/cache_search_students.dart';
import 'operations/student_search/search_cached_students.dart';
import 'operations/student_search/get_cached_participants.dart';

mixin ClassStudentSearchMixin on ClassLocalDataSourceBase {
  @override
  Future<UserModel?> getStudentById(String studentId) async {
    return getStudentByIdOp(localDatabase, studentId);
  }

  @override
  Future<void> cacheSearchStudents(List<UserModel> students) async {
    return cacheSearchStudentsOp(localDatabase, students);
  }

  @override
  Future<List<UserModel>> searchCachedStudents(String query) async {
    return searchCachedStudentsOp(localDatabase, query);
  }

  @override
  Future<List<UserModel>> getCachedParticipants(String classId) async {
    return getCachedParticipantsOp(localDatabase, classId);
  }
}
