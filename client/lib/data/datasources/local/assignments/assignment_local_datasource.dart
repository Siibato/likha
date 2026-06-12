import 'package:likha/data/models/assignments/assignment_model.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart'
    show AssignmentSubmissionModel, SubmissionListItemModel;
import 'package:likha/data/models/assignments/submission_file_model.dart';

abstract class AssignmentLocalDataSource {
  Future<List<AssignmentModel>> getCachedAssignments(String classId, {bool publishedOnly = false, String? studentId});
  Future<AssignmentModel> getCachedAssignmentDetail(String assignmentId);
  Future<void> cacheAssignments(List<AssignmentModel> assignments);
  Future<void> cacheAssignmentDetail(AssignmentModel assignment);
  Future<String> createSubmission({
    required String assignmentId,
    required String studentId,
    String studentName = '',
    String? textContent,
  });
  Future<void> updateSubmissionText({
    required String submissionId,
    required String textContent,
  });
  Future<void> stageFileForUpload({
    required String submissionId,
    required String fileName,
    required String fileType,
    required int fileSize,
    required String localPath,
  });
  Future<void> submitAssignment({
    required String submissionId,
    required String assignmentId,
  });
  Future<AssignmentSubmissionModel?> getCachedSubmission(String submissionId);
  Future<List<SubmissionListItemModel>> getCachedSubmissions(String assignmentId);
  Future<List<SubmissionFileModel>> getCachedSubmissionFiles(String submissionId);
  Future<void> cacheSubmissions(String assignmentId, List<SubmissionListItemModel> submissions);
  Future<bool> isFileCached(String fileId);
  Future<List<int>> getCachedFileBytes(String fileId);
  Future<void> cacheFileBytes(String fileId, String fileName, List<int> bytes);
  Future<void> gradeSubmission({
    required String submissionId,
    required int score,
    String? feedback,
  });
  Future<void> returnSubmission({required String submissionId});
  Future<void> cacheSubmissionDetail(AssignmentSubmissionModel submission);
  Future<void> cacheSubmissionFile(String submissionId, SubmissionFileModel file);
  Future<void> softDeleteSubmissionFile(String fileId);
  Future<void> markAssignmentPublished({required String assignmentId});
  Future<void> markAssignmentUnpublished({required String assignmentId});
  Future<void> updateAssignmentOrder({
    required String assignmentId,
    required int orderIndex,
  });
  Future<void> deleteAssignment({required String assignmentId});
  Future<void> clearAllCache();
  Future<(String submissionId, String status, int? score)?> getStudentSubmissionForAssignment(
    String assignmentId,
    String studentId,
  );
}