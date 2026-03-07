import 'package:dio/dio.dart';
import 'package:likha/core/constants/api_endpoints.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart';
import 'package:likha/data/models/assignments/submission_file_model.dart';

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

  Future<void> reorderAllAssignments({
    required String classId,
    required List<String> assignmentIds,
  });

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
      return await _dioClient.postTyped(
        ApiEndpoints.classAssignments(classId),
        data: data,
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<AssignmentModel>> getAssignments({
    required String classId,
  }) async {
    try {
      return await _dioClient.getTyped(
        ApiEndpoints.classAssignmentsList(classId),
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<AssignmentModel> getAssignmentDetail({
    required String assignmentId,
  }) async {
    try {
      return await _dioClient.getTyped(
        ApiEndpoints.assignmentDetail(assignmentId),
      );
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
      return await _dioClient.putTyped(
        ApiEndpoints.assignmentDetail(assignmentId),
        data: data,
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> deleteAssignment({required String assignmentId}) async {
    try {
      await _dioClient.deleteTyped(
        ApiEndpoints.assignmentDetail(assignmentId),
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
      return await _dioClient.postTyped(
        ApiEndpoints.assignmentPublish(assignmentId),
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<void> reorderAllAssignments({
    required String classId,
    required List<String> assignmentIds,
  }) async {
    try {
      await _dioClient.postTyped(
        ApiEndpoints.classAssignmentsReorder(classId),
        data: {'assignment_ids': assignmentIds},
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<SubmissionListItemModel>> getSubmissions({
    required String assignmentId,
  }) async {
    try {
      return await _dioClient.getTyped(
        ApiEndpoints.assignmentSubmissions(assignmentId),
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<AssignmentSubmissionModel> getSubmissionDetail({
    required String submissionId,
  }) async {
    try {
      return await _dioClient.getTyped(
        ApiEndpoints.assignmentSubmissionDetail(submissionId),
      );
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
      return await _dioClient.postTyped(
        ApiEndpoints.assignmentSubmissionGrade(submissionId),
        data: data,
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<AssignmentSubmissionModel> returnSubmission({
    required String submissionId,
  }) async {
    try {
      return await _dioClient.postTyped(
        ApiEndpoints.assignmentSubmissionReturn(submissionId),
      );
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
      return await _dioClient.postTyped(
        ApiEndpoints.assignmentSubmit(assignmentId),
        data: {'text_content': textContent},
      );
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
        ApiEndpoints.assignmentSubmissionUpload(submissionId).path,
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
      await _dioClient.deleteTyped(
        ApiEndpoints.submissionFileDelete(fileId),
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
      return await _dioClient.postTyped(
        ApiEndpoints.assignmentSubmissionSubmit(submissionId),
      );
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }

  @override
  Future<List<int>> downloadFile({required String fileId}) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.submissionFileDownload(fileId).path,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } on DioException catch (e) {
      throw _dioClient.handleError(e);
    }
  }
}
