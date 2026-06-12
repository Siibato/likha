import '../assignment_local_datasource_base.dart';
import 'operations/mutation/create_submission_locally.dart';
import 'operations/mutation/update_submission_text_locally.dart';
import 'operations/mutation/submit_assignment_locally.dart';
import 'operations/mutation/grade_submission_locally.dart';
import 'operations/mutation/return_submission_locally.dart';
import 'operations/mutation/mark_assignment_published_locally.dart';
import 'operations/mutation/mark_assignment_unpublished_locally.dart';
import 'operations/mutation/soft_delete_submission_file.dart';
import 'operations/mutation/update_assignment_order_locally.dart';

mixin AssignmentMutationMixin on AssignmentLocalDataSourceBase {
  @override
  Future<String> createSubmissionLocally({
    required String assignmentId,
    required String studentId,
    String studentName = '',
    String? textContent,
  }) async {
    return createSubmissionLocallyOp(localDatabase, syncQueue, assignmentId, studentId, studentName, textContent);
  }

  @override
  Future<void> updateSubmissionTextLocally({
    required String submissionId,
    required String textContent,
  }) async {
    return updateSubmissionTextLocallyOp(localDatabase, syncQueue, submissionId, textContent);
  }

  @override
  Future<void> submitAssignmentLocally({
    required String submissionId,
    required String assignmentId,
  }) async {
    return submitAssignmentLocallyOp(localDatabase, syncQueue, submissionId, assignmentId);
  }

  @override
  Future<void> gradeSubmissionLocally({
    required String submissionId,
    required int score,
    String? feedback,
  }) async {
    return gradeSubmissionLocallyOp(localDatabase, syncQueue, submissionId, score, feedback);
  }

  @override
  Future<void> returnSubmissionLocally({
    required String submissionId,
  }) async {
    return returnSubmissionLocallyOp(localDatabase, syncQueue, submissionId);
  }

  @override
  Future<void> markAssignmentPublishedLocally({required String assignmentId}) async {
    return markAssignmentPublishedLocallyOp(localDatabase, syncQueue, assignmentId);
  }

  @override
  Future<void> markAssignmentUnpublishedLocally({required String assignmentId}) async {
    return markAssignmentUnpublishedLocallyOp(localDatabase, syncQueue, assignmentId);
  }

  @override
  Future<void> updateAssignmentOrderLocally({
    required String assignmentId,
    required int orderIndex,
  }) async {
    return updateAssignmentOrderLocallyOp(localDatabase, assignmentId, orderIndex);
  }

  @override
  Future<void> softDeleteSubmissionFile(String fileId) async {
    return softDeleteSubmissionFileOp(localDatabase, fileId);
  }
}