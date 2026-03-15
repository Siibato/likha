import 'package:likha/data/models/assignments/assignment_model.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart'
    show AssignmentSubmissionModel, SubmissionListItemModel;
import 'package:likha/data/models/assignments/submission_file_model.dart';

abstract class AssignmentLocalDataSource {
  Future<List<AssignmentModel>> getCachedAssignments(String classId, {bool publishedOnly = false, String? studentId});
  Future<AssignmentModel> getCachedAssignmentDetail(String assignmentId);
  Future<void> cacheAssignments(List<AssignmentModel> assignments);
  Future<void> cacheAssignmentDetail(AssignmentModel assignment);
  Future<String> createSubmissionLocally({
    required String assignmentId,
    required String studentId,
    String studentName = '',
    String? textContent,
  });
  Future<void> updateSubmissionTextLocally({
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
  Future<void> submitAssignmentLocally({
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
  Future<void> gradeSubmissionLocally({
    required String submissionId,
    required int score,
    String? feedback,
  });
  Future<void> returnSubmissionLocally({
    required String submissionId,
  });
  Future<void> cacheSubmissionDetail(AssignmentSubmissionModel submission);
  Future<void> cacheSubmissionFile(String submissionId, SubmissionFileModel file);
  Future<void> softDeleteSubmissionFile(String fileId);
  Future<void> markAssignmentPublishedLocally({required String assignmentId});
  Future<void> markAssignmentUnpublishedLocally({required String assignmentId});
  Future<void> deleteAssignmentLocal({required String assignmentId});
  Future<void> clearAllCache();
  Future<(String submissionId, String status, int? score)?> getStudentSubmissionForAssignment(
    String assignmentId,
    String studentId,
  );
}