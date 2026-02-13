import 'package:dio/dio.dart';
import 'package:likha/core/constants/api_constants.dart';
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
      final response = await _dioClient.dio.post(
        ApiConstants.classes,
        data: {
          'title': title,
          if (description != null) 'description': description,
        },
      );

      final responseData = response.data['data'] ?? response.data;
      return ClassModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<ClassModel>> getMyClasses() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.classes);

      final responseData = response.data['data'] ?? response.data;
      final classes = (responseData['classes'] as List<dynamic>)
          .map((e) => ClassModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return classes;
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<ClassDetailModel> getClassDetail({required String classId}) async {
    try {
      final response =
          await _dioClient.dio.get(ApiConstants.classDetail(classId));

      final responseData = response.data['data'] ?? response.data;
      return ClassDetailModel.fromJson(responseData);
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
      final response = await _dioClient.dio.put(
        ApiConstants.classDetail(classId),
        data: {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
        },
      );

      final responseData = response.data['data'] ?? response.data;
      return ClassModel.fromJson(responseData);
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
      final response = await _dioClient.dio.post(
        ApiConstants.classStudents(classId),
        data: {'student_id': studentId},
      );

      final responseData = response.data['data'] ?? response.data;
      return EnrollmentModel.fromJson(responseData);
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
      await _dioClient.dio.delete(
        ApiConstants.classStudent(classId, studentId),
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<UserModel>> searchStudents({String? query}) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.searchStudents,
        queryParameters: {
          if (query != null && query.isNotEmpty) 'q': query,
        },
      );

      final responseData = response.data['data'] ?? response.data;
      final students = (responseData as List<dynamic>)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return students;
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }
}
