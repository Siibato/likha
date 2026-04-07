import 'package:dio/dio.dart';
import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/data/models/classes/class_detail_model.dart';
import 'package:likha/data/models/classes/class_model.dart';

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
  }) async {
    try {
      return await _dioClient.postTyped(
        ApiEndpoints.classCreate,
        data: {
          'title': title,
          if (description != null) 'description': description,
          if (teacherId != null) 'teacher_id': teacherId,
          'is_advisory': isAdvisory,
        },
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<ClassModel>> getMyClasses() async {
    try {
      return await _dioClient.getTyped(ApiEndpoints.classes);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<ClassModel>> getAllClasses() async {
    try {
      return await _dioClient.getTyped(ApiEndpoints.classes);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<ClassDetailModel> getClassDetail({required String classId}) async {
    try {
      return await _dioClient.getTyped(ApiEndpoints.classDetail(classId));
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<ClassModel> updateClass({
    required String classId,
    String? title,
    String? description,
    String? teacherId,
    bool? isAdvisory,
  }) async {
    try {
      return await _dioClient.putTyped(
        ApiEndpoints.classUpdate(classId),
        data: {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (teacherId != null) 'teacher_id': teacherId,
          if (isAdvisory != null) 'is_advisory': isAdvisory,
        },
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<ParticipantModel> addStudent({
    required String classId,
    required String studentId,
  }) async {
    try {
      return await _dioClient.postTyped(
        ApiEndpoints.classStudents(classId),
        data: {'student_id': studentId},
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> removeStudent({
    required String classId,
    required String studentId,
  }) async {
    try {
      await _dioClient.deleteTyped(
        ApiEndpoints.classStudent(classId, studentId),
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> deleteClass({required String classId}) async {
    try {
      await _dioClient.deleteTyped(
        ApiEndpoints.classDelete(classId),
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<UserModel>> searchStudents({String? query}) async {
    try {
      return await _dioClient.getTyped(
        ApiEndpoints.searchStudents,
        queryParameters: {
          if (query != null && query.isNotEmpty) 'q': query,
        },
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }
}
