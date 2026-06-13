import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/assignments/student_assignment_submission_item_model.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart';
import 'package:likha/data/models/assignments/submission_file_model.dart';
import 'package:likha/data/datasources/remote/assignments/operations/assignments.dart' as ops;

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

  Future<AssignmentModel> unpublishAssignment({required String assignmentId});

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
    void Function(int sent, int total)? onSendProgress,
  });

  Future<void> deleteFile({required String fileId});

  Future<AssignmentSubmissionModel> submitAssignment({
    required String submissionId,
  });

  Future<List<int>> downloadFile({required String fileId});

  Future<List<StudentAssignmentSubmissionItemModel>> getStudentAssignmentSubmissions({
    required String classId,
    required String studentId,
  });
}

class AssignmentRemoteDataSourceImpl implements AssignmentRemoteDataSource {
  final DioClient _dioClient;

  AssignmentRemoteDataSourceImpl(this._dioClient);

  @override
  Future<AssignmentModel> createAssignment({
    required String classId,
    required Map<String, dynamic> data,
  }) =>
      ops.createAssignment(
        _dioClient,
        classId: classId,
        data: data,
      );

  @override
  Future<List<AssignmentModel>> getAssignments({
    required String classId,
  }) =>
      ops.getAssignments(
        _dioClient,
        classId: classId,
      );

  @override
  Future<AssignmentModel> getAssignmentDetail({
    required String assignmentId,
  }) =>
      ops.getAssignmentDetail(
        _dioClient,
        assignmentId: assignmentId,
      );

  @override
  Future<AssignmentModel> updateAssignment({
    required String assignmentId,
    required Map<String, dynamic> data,
  }) =>
      ops.updateAssignment(
        _dioClient,
        assignmentId: assignmentId,
        data: data,
      );

  @override
  Future<void> deleteAssignment({required String assignmentId}) =>
      ops.deleteAssignment(
        _dioClient,
        assignmentId: assignmentId,
      );

  @override
  Future<AssignmentModel> publishAssignment({
    required String assignmentId,
  }) =>
      ops.publishAssignment(
        _dioClient,
        assignmentId: assignmentId,
      );

  @override
  Future<AssignmentModel> unpublishAssignment({
    required String assignmentId,
  }) =>
      ops.unpublishAssignment(
        _dioClient,
        assignmentId: assignmentId,
      );

  @override
  Future<void> reorderAllAssignments({
    required String classId,
    required List<String> assignmentIds,
  }) =>
      ops.reorderAllAssignments(
        _dioClient,
        classId: classId,
        assignmentIds: assignmentIds,
      );

  @override
  Future<List<SubmissionListItemModel>> getSubmissions({
    required String assignmentId,
  }) =>
      ops.getSubmissions(
        _dioClient,
        assignmentId: assignmentId,
      );

  @override
  Future<AssignmentSubmissionModel> getSubmissionDetail({
    required String submissionId,
  }) =>
      ops.getSubmissionDetail(
        _dioClient,
        submissionId: submissionId,
      );

  @override
  Future<AssignmentSubmissionModel> gradeSubmission({
    required String submissionId,
    required Map<String, dynamic> data,
  }) =>
      ops.gradeSubmission(
        _dioClient,
        submissionId: submissionId,
        data: data,
      );

  @override
  Future<AssignmentSubmissionModel> returnSubmission({
    required String submissionId,
  }) =>
      ops.returnSubmission(
        _dioClient,
        submissionId: submissionId,
      );

  @override
  Future<AssignmentSubmissionModel> createSubmission({
    required String assignmentId,
    String? textContent,
  }) =>
      ops.createSubmission(
        _dioClient,
        assignmentId: assignmentId,
        textContent: textContent,
      );

  @override
  Future<SubmissionFileModel> uploadFile({
    required String submissionId,
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onSendProgress,
  }) =>
      ops.uploadFile(
        _dioClient,
        submissionId: submissionId,
        filePath: filePath,
        fileName: fileName,
        onSendProgress: onSendProgress,
      );

  @override
  Future<void> deleteFile({required String fileId}) =>
      ops.deleteFile(
        _dioClient,
        fileId: fileId,
      );

  @override
  Future<AssignmentSubmissionModel> submitAssignment({
    required String submissionId,
  }) =>
      ops.submitAssignment(
        _dioClient,
        submissionId: submissionId,
      );

  @override
  Future<List<int>> downloadFile({required String fileId}) =>
      ops.downloadFile(
        _dioClient,
        fileId: fileId,
      );

  @override
  Future<List<StudentAssignmentSubmissionItemModel>> getStudentAssignmentSubmissions({
    required String classId,
    required String studentId,
  }) =>
      ops.getStudentAssignmentSubmissions(
        _dioClient,
        classId: classId,
        studentId: studentId,
      );
}
