import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/data/models/classes/class_detail_model.dart';
import 'package:likha/data/models/classes/class_model.dart';
import 'operations/classes.dart' as ops;

abstract class ClassLocalDataSource {
  Future<List<ClassModel>> getCachedClasses({String? teacherId});
  Future<List<ClassModel>> getCachedClassesForUser(String userId);
  Future<ClassDetailModel> getCachedClassDetail(String classId);
  Future<void> cacheClasses(List<ClassModel> classes);

  Future<void> cacheStudentParticipation({
    required String classId,
    required String userId,
    required DateTime joinedAt,
  });

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
    bool? isAdvisory,
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
  Future<List<UserModel>> getCachedParticipants(String classId);
  Future<Set<String>> getParticipantIds(String classId);
  Future<ClassDetailModel?> buildClassDetailFromParticipants(String classId);
  Future<void> clearAllCache();
}

class ClassLocalDataSourceImpl implements ClassLocalDataSource {
  final LocalDatabase localDatabase;
  final SyncQueue syncQueue;

  ClassLocalDataSourceImpl(this.localDatabase, this.syncQueue);

  @override
  Future<List<ClassModel>> getCachedClasses({String? teacherId}) =>
      ops.getCachedClasses(localDatabase, teacherId);

  @override
  Future<List<ClassModel>> getCachedClassesForUser(String userId) =>
      ops.getCachedClassesForUser(localDatabase, userId);

  @override
  Future<ClassDetailModel> getCachedClassDetail(String classId) =>
      ops.getCachedClassDetail(localDatabase, classId);

  @override
  Future<void> cacheClasses(List<ClassModel> classes) =>
      ops.cacheClasses(localDatabase, classes);

  @override
  Future<void> cacheStudentParticipation({
    required String classId,
    required String userId,
    required DateTime joinedAt,
  }) =>
      ops.cacheStudentParticipation(localDatabase, classId, userId, joinedAt);

  @override
  Future<void> cacheClassDetail(ClassDetailModel classDetail) =>
      ops.cacheClassDetail(localDatabase, classDetail);

  @override
  Future<ClassModel> createClassLocally({
    required String title,
    required String description,
    required String teacherId,
    required String teacherUsername,
    required String teacherFullName,
  }) =>
      ops.createClassLocally(
        localDatabase,
        syncQueue,
        title,
        description,
        teacherId,
        teacherUsername,
        teacherFullName,
      );

  @override
  Future<void> updateClassLocally({
    required String classId,
    required String title,
    required String description,
    bool? isAdvisory,
  }) =>
      ops.updateClassLocally(
        localDatabase,
        syncQueue,
        classId,
        title,
        description,
        isAdvisory,
      );

  @override
  Future<String> addStudentLocally({
    required String classId,
    required UserModel student,
  }) =>
      ops.addStudentLocally(localDatabase, classId, student);

  @override
  Future<void> removeStudentLocally({
    required String classId,
    required String studentId,
  }) =>
      ops.removeStudentLocally(localDatabase, classId, studentId);

  @override
  Future<UserModel?> getStudentById(String studentId) =>
      ops.getStudentById(localDatabase, studentId);

  @override
  Future<void> cacheSearchStudents(List<UserModel> students) =>
      ops.cacheSearchStudents(localDatabase, students);

  @override
  Future<List<UserModel>> searchCachedStudents(String query) =>
      ops.searchCachedStudents(localDatabase, query);

  @override
  Future<List<UserModel>> getCachedParticipants(String classId) =>
      ops.getCachedParticipants(localDatabase, classId);

  @override
  Future<Set<String>> getParticipantIds(String classId) =>
      ops.getParticipantIds(localDatabase, classId);

  @override
  Future<ClassDetailModel?> buildClassDetailFromParticipants(String classId) =>
      ops.buildClassDetailFromParticipants(localDatabase, classId);

  @override
  Future<void> clearAllCache() =>
      ops.clearAllCache(localDatabase);
}