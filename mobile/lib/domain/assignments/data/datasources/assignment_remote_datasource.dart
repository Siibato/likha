import 'package:dio/dio.dart';
import 'package:likha/core/constants/api_constants.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/domain/assignments/data/models/assignment_model.dart';
import 'package:likha/domain/assignments/data/models/assignment_submission_model.dart';
import 'package:likha/domain/assignments/data/models/submission_file_model.dart';

abstract class AssignmentRemoteDataSource {
  Future<AssignmentModel> createAssignment({
    required String classId,
    required Map<String, dynamic> data,
  });

  Future<List<AssignmentModel>> getAssignments({required String classId});

  Future<AssignmentModel> getAssignmentDetail({required String assignmentId});

  Future<AssignmentModel> updateAssignment({
    required String assignmentId,
    required Map<String, dynamic> data,
  });

  Future<void> deleteAssignment({required String assignmentId});

  Future<AssignmentModel> publishAssignment({required String assignmentId});

  Future<List<SubmissionListItemModel>> getSubmissions({
    required String assignmentId,
  });

  Future<AssignmentSubmissionModel> getSubmissionDetail({
    required String submissionId,
  });

  Future<AssignmentSubmissionModel> gradeSubmission({
    required String submissionId,
    required Map<String, dynamic> data,
  });

  Future<AssignmentSubmissionModel> returnSubmission({
    required String submissionId,
  });

  // Student endpoints
  Future<AssignmentSubmissionModel> createSubmission({
    required String assignmentId,
    String? textContent,
  });

  Future<SubmissionFileModel> uploadFile({
    required String submissionId,
    required String filePath,
    required String fileName,
  });

  Future<void> deleteFile({required String fileId});

  Future<AssignmentSubmissionModel> submitAssignment({
    required String submissionId,
  });

  Future<List<int>> downloadFile({required String fileId});
}

class AssignmentRemoteDataSourceImpl implements AssignmentRemoteDataSource {
  final DioClient _dioClient;

  AssignmentRemoteDataSourceImpl(this._dioClient);

  @override
  Future<AssignmentModel> createAssignment({
    required String classId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.classAssignments(classId),
        data: data,
      );
      final responseData = response.data['data'] ?? response.data;
      return AssignmentModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<AssignmentModel>> getAssignments({
    required String classId,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.classAssignments(classId),
      );
      final responseData = response.data['data'] ?? response.data;
      final assignments = (responseData['assignments'] as List<dynamic>)
          .map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return assignments;
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<AssignmentModel> getAssignmentDetail({
    required String assignmentId,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.assignmentDetail(assignmentId),
      );
      final responseData = response.data['data'] ?? response.data;
      return AssignmentModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<AssignmentModel> updateAssignment({
    required String assignmentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dioClient.dio.put(
        ApiConstants.assignmentDetail(assignmentId),
        data: data,
      );
      final responseData = response.data['data'] ?? response.data;
      return AssignmentModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> deleteAssignment({required String assignmentId}) async {
    try {
      await _dioClient.dio.delete(
        ApiConstants.assignmentDetail(assignmentId),
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<AssignmentModel> publishAssignment({
    required String assignmentId,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.assignmentPublish(assignmentId),
      );
      final responseData = response.data['data'] ?? response.data;
      return AssignmentModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<SubmissionListItemModel>> getSubmissions({
    required String assignmentId,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.assignmentSubmissions(assignmentId),
      );
      final responseData = response.data['data'] ?? response.data;
      final submissions = (responseData['submissions'] as List<dynamic>)
          .map((e) =>
              SubmissionListItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return submissions;
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<AssignmentSubmissionModel> getSubmissionDetail({
    required String submissionId,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.assignmentSubmissionDetail(submissionId),
      );
      final responseData = response.data['data'] ?? response.data;
      return AssignmentSubmissionModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<AssignmentSubmissionModel> gradeSubmission({
    required String submissionId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.assignmentSubmissionGrade(submissionId),
        data: data,
      );
      final responseData = response.data['data'] ?? response.data;
      return AssignmentSubmissionModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<AssignmentSubmissionModel> returnSubmission({
    required String submissionId,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.assignmentSubmissionReturn(submissionId),
      );
      final responseData = response.data['data'] ?? response.data;
      return AssignmentSubmissionModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<AssignmentSubmissionModel> createSubmission({
    required String assignmentId,
    String? textContent,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.assignmentSubmit(assignmentId),
        data: {'text_content': textContent},
      );
      final responseData = response.data['data'] ?? response.data;
      return AssignmentSubmissionModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<SubmissionFileModel> uploadFile({
    required String submissionId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response = await _dioClient.dio.post(
        ApiConstants.assignmentSubmissionUpload(submissionId),
        data: formData,
      );
      final responseData = response.data['data'] ?? response.data;
      return SubmissionFileModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> deleteFile({required String fileId}) async {
    try {
      await _dioClient.dio.delete(
        ApiConstants.submissionFileDelete(fileId),
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<AssignmentSubmissionModel> submitAssignment({
    required String submissionId,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.assignmentSubmissionSubmit(submissionId),
      );
      final responseData = response.data['data'] ?? response.data;
      return AssignmentSubmissionModel.fromJson(responseData);
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<int>> downloadFile({required String fileId}) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.submissionFileDownload(fileId),
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }
}
