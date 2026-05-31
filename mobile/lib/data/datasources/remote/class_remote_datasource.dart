import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/data/models/classes/class_detail_model.dart';
import 'package:likha/data/models/classes/class_model.dart';
import 'package:likha/data/datasources/remote/operations/classes/classes.dart' as ops;

abstract class ClassRemoteDataSource {
  Future<ClassModel> createClass({
    required String title,
    String? description,
    String? teacherId,
    bool isAdvisory = false,
  });

  Future<List<ClassModel>> getMyClasses();

  Future<List<ClassModel>> getAllClasses();

  Future<ClassDetailModel> getClassDetail({required String classId});

  Future<ClassModel> updateClass({
    required String classId,
    String? title,
    String? description,
    String? teacherId,
    bool? isAdvisory,
  });

  Future<ParticipantModel> addStudent({
    required String classId,
    required String studentId,
  });

  Future<void> removeStudent({
    required String classId,
    required String studentId,
  });

  Future<List<UserModel>> searchStudents({String? query});

  Future<void> deleteClass({required String classId});
}

class ClassRemoteDataSourceImpl implements ClassRemoteDataSource {
  final DioClient _dioClient;

  ClassRemoteDataSourceImpl(this._dioClient);

  @override
  Future<ClassModel> createClass({
    required String title,
    String? description,
    String? teacherId,
    bool isAdvisory = false,
  }) =>
      ops.createClass(
        _dioClient,
        title: title,
        description: description,
        teacherId: teacherId,
        isAdvisory: isAdvisory,
      );

  @override
  Future<List<ClassModel>> getMyClasses() =>
      ops.getMyClasses(
        _dioClient,
      );

  @override
  Future<List<ClassModel>> getAllClasses() =>
      ops.getAllClasses(
        _dioClient,
      );

  @override
  Future<ClassDetailModel> getClassDetail({required String classId}) =>
      ops.getClassDetail(
        _dioClient,
        classId: classId,
      );

  @override
  Future<ClassModel> updateClass({
    required String classId,
    String? title,
    String? description,
    String? teacherId,
    bool? isAdvisory,
  }) =>
      ops.updateClass(
        _dioClient,
        classId: classId,
        title: title,
        description: description,
        teacherId: teacherId,
        isAdvisory: isAdvisory,
      );

  @override
  Future<ParticipantModel> addStudent({
    required String classId,
    required String studentId,
  }) =>
      ops.addStudent(
        _dioClient,
        classId: classId,
        studentId: studentId,
      );

  @override
  Future<void> removeStudent({
    required String classId,
    required String studentId,
  }) =>
      ops.removeStudent(
        _dioClient,
        classId: classId,
        studentId: studentId,
      );

  @override
  Future<void> deleteClass({required String classId}) =>
      ops.deleteClass(
        _dioClient,
        classId: classId,
      );

  @override
  Future<List<UserModel>> searchStudents({String? query}) =>
      ops.searchStudents(
        _dioClient,
        query: query,
      );
}
