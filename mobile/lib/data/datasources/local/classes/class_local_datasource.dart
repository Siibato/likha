import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/data/models/classes/class_detail_model.dart';
import 'package:likha/data/models/classes/class_model.dart';

abstract class ClassLocalDataSource {
  Future<List<ClassModel>> getCachedClasses({String? teacherId});
  Future<List<ClassModel>> getCachedClassesForUser(String userId);
  Future<ClassDetailModel> getCachedClassDetail(String classId);
  Future<void> cacheClasses(List<ClassModel> classes);
  Future<void> cacheClassDetail(ClassDetailModel classDetail);
  Future<ClassModel> createClassLocally({
    required String title,
    required String description,
    required String teacherId,
    required String teacherUsername,
    required String teacherFullName,
  });
  Future<void> updateClassLocally({
    required String classId,
    required String title,
    required String description,
  });
  Future<String> addStudentLocally({
    required String classId,
    required UserModel student,
  });
  Future<void> removeStudentLocally({
    required String classId,
    required String studentId,
  });
  Future<UserModel?> getStudentById(String studentId);
  Future<void> cacheSearchStudents(List<UserModel> students);
  Future<List<UserModel>> searchCachedStudents(String query);
  Future<List<UserModel>> getCachedEnrolledStudents(String classId);
  Future<Set<String>> getEnrolledStudentIds(String classId);
  Future<ClassDetailModel?> buildClassDetailFromEnrollments(String classId);
  Future<void> clearAllCache();
}