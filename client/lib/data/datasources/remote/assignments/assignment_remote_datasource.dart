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
    String? idempotencyKey,
  });

  Future<List<AssignmentModel>> getAssignments({required String classId});

  Future<AssignmentModel> getAssignmentDetail({required String assignmentId});

  Future<AssignmentModel> updateAssignment({
    required String assignmentId,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  });

  Future<void> deleteAssignment({required String assignmentId, String? idempotencyKey});

  Future<AssignmentModel> publishAssignment({required String assignmentId, String? idempotencyKey});

  Future<AssignmentModel> unpublishAssignment({required String assignmentId, String? idempotencyKey});

  Future<void> reorderAllAssignments({
    required String classId,
    required List<String> assignmentIds,
    String? idempotencyKey,
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
    String? idempotencyKey,
  });

  Future<AssignmentSubmissionModel> returnSubmission({
    required String submissionId,
    String? idempotencyKey,
  });

  // Student endpoints
  Future<AssignmentSubmissionModel> createSubmission({
    required String assignmentId,
    String? textContent,
    String? idempotencyKey,
  });

  Future<SubmissionFileModel> uploadFile({
    required String submissionId,
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onSendProgress,
    String? idempotencyKey,
  });

  Future<void> deleteFile({required String fileId, String? idempotencyKey});

  Future<AssignmentSubmissionModel> submitAssignment({
    required String submissionId,
    String? idempotencyKey,
  });

  Future<List<int>> downloadFile({required String fileId});

  Future<AssignmentSubmissionModel?> getStudentAssignmentSubmission({
    required String assignmentId,
    required String studentId,
  });

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
    String? idempotencyKey,
  }) =>
      ops.createAssignment(
        _dioClient,
        classId: classId,
        data: data,
        idempotencyKey: idempotencyKey,
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
    String? idempotencyKey,
  }) =>
      ops.updateAssignment(
        _dioClient,
        assignmentId: assignmentId,
        data: data,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> deleteAssignment({required String assignmentId, String? idempotencyKey}) =>
      ops.deleteAssignment(
        _dioClient,
        assignmentId: assignmentId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<AssignmentModel> publishAssignment({
    required String assignmentId,
    String? idempotencyKey,
  }) =>
      ops.publishAssignment(
        _dioClient,
        assignmentId: assignmentId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<AssignmentModel> unpublishAssignment({
    required String assignmentId,
    String? idempotencyKey,
  }) =>
      ops.unpublishAssignment(
        _dioClient,
        assignmentId: assignmentId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> reorderAllAssignments({
    required String classId,
    required List<String> assignmentIds,
    String? idempotencyKey,
  }) =>
      ops.reorderAllAssignments(
        _dioClient,
        classId: classId,
        assignmentIds: assignmentIds,
        idempotencyKey: idempotencyKey,
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
    String? idempotencyKey,
  }) =>
      ops.gradeSubmission(
        _dioClient,
        submissionId: submissionId,
        data: data,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<AssignmentSubmissionModel> returnSubmission({
    required String submissionId,
    String? idempotencyKey,
  }) =>
      ops.returnSubmission(
        _dioClient,
        submissionId: submissionId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<AssignmentSubmissionModel> createSubmission({
    required String assignmentId,
    String? textContent,
    String? idempotencyKey,
  }) =>
      ops.createSubmission(
        _dioClient,
        assignmentId: assignmentId,
        textContent: textContent,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<SubmissionFileModel> uploadFile({
    required String submissionId,
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onSendProgress,
    String? idempotencyKey,
  }) =>
      ops.uploadFile(
        _dioClient,
        submissionId: submissionId,
        filePath: filePath,
        fileName: fileName,
        onSendProgress: onSendProgress,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> deleteFile({required String fileId, String? idempotencyKey}) =>
      ops.deleteFile(
        _dioClient,
        fileId: fileId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<AssignmentSubmissionModel> submitAssignment({
    required String submissionId,
    String? idempotencyKey,
  }) =>
      ops.submitAssignment(
        _dioClient,
        submissionId: submissionId,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<List<int>> downloadFile({required String fileId}) =>
      ops.downloadFile(
        _dioClient,
        fileId: fileId,
      );

  @override
  Future<AssignmentSubmissionModel?> getStudentAssignmentSubmission({
    required String assignmentId,
    required String studentId,
  }) =>
      ops.getStudentAssignmentSubmission(
        _dioClient,
        assignmentId: assignmentId,
        studentId: studentId,
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
