import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/data/models/classes/class_detail_model.dart';
import 'package:likha/data/models/classes/class_model.dart';
import 'package:likha/data/datasources/remote/classes/operations/classes.dart' as ops;

abstract class ClassRemoteDataSource {
  Future<ClassModel> createClass({
    required String title,
    String? description,
    String? teacherId,
    bool isAdvisory = false,
    String? idempotencyKey,
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
    String? idempotencyKey,
  });

  Future<ParticipantModel> addStudent({
    required String classId,
    required String studentId,
    String? idempotencyKey,
  });

  Future<void> removeStudent({
    required String classId,
    required String studentId,
    String? idempotencyKey,
  });

  Future<List<UserModel>> searchStudents({String? query});

  Future<List<UserModel>> getParticipants({required String classId});

  Future<void> deleteClass({
    required String classId,
    String? idempotencyKey,
  });
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
    String? idempotencyKey,
  }) =>
      ops.createClass(
        _dioClient,
        title: title,
        description: description,
        teacherId: teacherId,
        isAdvisory: isAdvisory,
        idempotencyKey: idempotencyKey,
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
    String? idempotencyKey,
  }) =>
      ops.updateClass(
        _dioClient,
        classId: classId,
        title: title,
        description: description,
        teacherId: teacherId,
        isAdvisory: isAdvisory,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<ParticipantModel> addStudent({
    required String classId,
    required String studentId,
    String? idempotencyKey,
  }) =>
      ops.addStudent(
        _dioClient,
        classId: classId,
        studentId: studentId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> removeStudent({
    required String classId,
    required String studentId,
    String? idempotencyKey,
  }) =>
      ops.removeStudent(
        _dioClient,
        classId: classId,
        studentId: studentId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> deleteClass({
    required String classId,
    String? idempotencyKey,
  }) =>
      ops.deleteClass(
        _dioClient,
        classId: classId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<List<UserModel>> searchStudents({String? query}) =>
      ops.searchStudents(
        _dioClient,
        query: query,
      );

  @override
  Future<List<UserModel>> getParticipants({required String classId}) =>
      ops.getParticipants(
        _dioClient,
        classId: classId,
      );
}
