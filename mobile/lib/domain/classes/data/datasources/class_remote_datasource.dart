import 'package:dio/dio.dart';
import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/domain/auth/data/models/user_model.dart';
import 'package:likha/domain/classes/data/models/class_detail_model.dart';
import 'package:likha/domain/classes/data/models/class_model.dart';

abstract class ClassRemoteDataSource {
  Future<ClassModel> createClass({
    required String title,
    String? description,
  });

  Future<List<ClassModel>> getMyClasses();

  Future<ClassDetailModel> getClassDetail({required String classId});

  Future<ClassModel> updateClass({
    required String classId,
    String? title,
    String? description,
  });

  Future<EnrollmentModel> addStudent({
    required String classId,
    required String studentId,
  });

  Future<void> removeStudent({
    required String classId,
    required String studentId,
  });

  Future<List<UserModel>> searchStudents({String? query});
}

class ClassRemoteDataSourceImpl implements ClassRemoteDataSource {
  final DioClient _dioClient;

  ClassRemoteDataSourceImpl(this._dioClient);

  @override
  Future<ClassModel> createClass({
    required String title,
    String? description,
  }) async {
    try {
      return await _dioClient.postTyped(
        ApiEndpoints.classCreate(title),
        data: {
          'title': title,
          if (description != null) 'description': description,
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
  }) async {
    try {
      return await _dioClient.putTyped(
        ApiEndpoints.classCreate(classId),
        data: {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
        },
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<EnrollmentModel> addStudent({
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
